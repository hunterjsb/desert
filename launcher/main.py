#!/usr/bin/env python3
"""Desert Launcher: install published builds or run local source worktrees."""
from __future__ import annotations

import json
import os
import platform
import plistlib
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
import zipfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

from PySide6.QtCore import Qt, QThread, Signal
from PySide6.QtGui import QColor, QFont, QIcon, QLinearGradient, QPainter, QPixmap
from PySide6.QtWidgets import (
    QApplication, QCheckBox, QComboBox, QFileDialog, QHBoxLayout, QLabel,
    QHeaderView, QLineEdit, QMainWindow, QMessageBox, QPushButton, QTabWidget,
    QTableWidget, QTableWidgetItem, QTextBrowser, QVBoxLayout, QWidget,
)

OWNER = "hunterjsb"
REPO = "desert"
API = f"https://api.github.com/repos/{OWNER}/{REPO}/releases?per_page=100"
APP_NAME = "Desert Launcher"


def user_data() -> Path:
    if sys.platform == "win32":
        return Path(os.environ.get("LOCALAPPDATA", Path.home() / "AppData/Local")) / "Desert Launcher"
    if sys.platform == "darwin":
        return Path.home() / "Library/Application Support/Desert Launcher"
    return Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "desert-launcher"


def resource_path(relative: str) -> Path:
    base = Path(getattr(sys, "_MEIPASS", Path(__file__).resolve().parents[1]))
    return base / relative


def config_file() -> Path:
    if sys.platform == "win32":
        base = Path(os.environ.get("APPDATA", Path.home() / "AppData/Roaming"))
    elif sys.platform == "darwin":
        base = Path.home() / "Library/Preferences"
    else:
        base = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    return base / "desert-launcher" / "settings.json"


def default_repo(settings: dict) -> str:
    candidates = [settings.get("repo"), str(Path(__file__).resolve().parents[1]), str(Path.cwd())]
    home = Path.home()
    candidates.extend(str(home / suffix) for suffix in (
        "code/desert", "Desktop/code/desert", "Projects/desert", "src/desert",
    ))
    for candidate in candidates:
        if candidate and (Path(candidate).expanduser() / ".git").exists():
            return str(Path(candidate).expanduser())
    return ""


def read_settings() -> dict:
    try:
        value = json.loads(config_file().read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else {}
    except (OSError, json.JSONDecodeError):
        legacy_root = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
        try:
            value = json.loads((legacy_root / "desert-worktree-picker/settings.json").read_text(encoding="utf-8"))
            return value if isinstance(value, dict) else {}
        except (OSError, json.JSONDecodeError):
            return {}


def write_settings(value: dict) -> None:
    path = config_file()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def platform_asset() -> str:
    machine = platform.machine().lower()
    if sys.platform == "win32":
        return "windows-x86_64" if machine in ("amd64", "x86_64") else ""
    if sys.platform == "darwin":
        return "macos-universal" if machine in ("arm64", "aarch64", "x86_64") else ""
    if sys.platform.startswith("linux"):
        return "linux-x86_64" if machine in ("amd64", "x86_64") else ""
    return ""


@dataclass
class Release:
    tag: str
    title: str
    version: str
    published: str
    notes: str
    asset_url: str | None
    asset_name: str | None


def fetch_releases() -> list[Release]:
    request = urllib.request.Request(API, headers={"Accept": "application/vnd.github+json", "User-Agent": "Desert-Launcher"})
    with urllib.request.urlopen(request, timeout=20) as response:
        entries = json.load(response)
    suffix = platform_asset()
    results = []
    for entry in entries:
        if entry.get("draft"):
            continue
        tag = entry.get("tag_name", "")
        if not tag.startswith("v"):
            continue
        assets = entry.get("assets", [])
        asset = next((a for a in assets if a.get("name", "").startswith("desert-") and a.get("name", "").endswith(f"-{suffix}.zip")), None) if suffix else None
        results.append(Release(
            tag=tag, title=entry.get("name") or tag, version=tag.removeprefix("v"),
            published=entry.get("published_at", ""), notes=entry.get("body") or "",
            asset_url=asset.get("browser_download_url") if asset else None,
            asset_name=asset.get("name") if asset else None,
        ))
    results.sort(key=lambda release: release.published, reverse=True)
    return results


def installed_games() -> dict[str, Path]:
    config = read_settings()
    roots = {user_data() / "games"}
    if config.get("install_root"):
        roots.add(Path(config["install_root"]).expanduser())
    roots.update(Path(root).expanduser() for root in config.get("install_roots", []) if root)
    home = Path.home()
    roots.update(home / path for path in ("Games", "Applications", "Downloads"))
    if sys.platform == "win32":
        roots.add(Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Desert")
    found: dict[str, Path] = {}
    for root in roots:
        if not root.is_dir():
            continue
        for path in root.iterdir():
            marker = path / ".desert-install.json"
            if not path.is_dir() or (not marker.is_file() and "desert" not in path.name.casefold()) or not game_executable(path):
                continue
            if marker.is_file():
                try:
                    version = json.loads(marker.read_text(encoding="utf-8")).get("version", path.name.removeprefix("desert-"))
                except (OSError, json.JSONDecodeError):
                    version = path.name.removeprefix("desert-")
            else:
                name = path.name.removeprefix("desert-")
                suffixes = ("-linux-x86_64", "-windows-x86_64", "-macos-universal")
                version = next((name.removesuffix(suffix) for suffix in suffixes if name.endswith(suffix)), name)
                info = path / "Contents/Info.plist"
                if info.is_file():
                    try:
                        with info.open("rb") as source:
                            version = plistlib.load(source).get("CFBundleShortVersionString", version)
                    except (OSError, plistlib.InvalidFileException):
                        pass
            found[str(version)] = path
    return found


def installation_for(version: str, installations: dict[str, Path]) -> Path | None:
    direct = installations.get(version)
    if direct:
        return direct
    return installations.get(version.split("-", 1)[0])


def game_executable(folder: Path) -> Path | None:
    if sys.platform == "win32":
        path = folder / "Desert.exe"
    elif sys.platform == "darwin":
        path = folder / "Desert.app/Contents/MacOS/Desert"
    else:
        path = folder / "Desert.x86_64"
    if path.is_file():
        return path
    return next((candidate for candidate in folder.rglob(path.name) if candidate.is_file()), None)


@dataclass
class SourceTree:
    path: Path
    branch: str
    timestamp: str
    message: str
    version: str
    dirty: bool


def git_output(args: list[str], cwd: Path) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, text=True, capture_output=True, check=False)
    if result.returncode:
        return ""
    return result.stdout.strip()


def project_version(path: Path) -> str:
    try:
        for line in (path / "project.godot").read_text(encoding="utf-8").splitlines():
            if line.startswith("config/version="):
                return line.partition("=")[2].strip().strip('"')
    except OSError:
        pass
    return "unknown"


def list_sources(repo: Path) -> list[SourceTree]:
    if not (repo / ".git").exists():
        raise RuntimeError("That folder is not a Git checkout. Choose the repository root.")
    raw = git_output(["worktree", "list", "--porcelain"], repo)
    if not raw:
        raise RuntimeError("Git could not list worktrees for this repository.")
    trees = []
    entry: dict[str, str] = {}
    for line in [*raw.splitlines(), ""]:
        if line:
            key, _, value = line.partition(" ")
            entry[key] = value
            continue
        path = Path(entry.get("worktree", ""))
        if path.is_dir() and (path / "project.godot").is_file():
            commit = git_output(["log", "-1", "--format=%ct%x00%s"], path)
            timestamp, _, message = commit.partition("\0")
            branch = entry.get("branch", "detached").removeprefix("refs/heads/")
            if branch == "detached":
                branch += f" ({path.name})"
            trees.append(SourceTree(path, branch, timestamp, message, project_version(path), bool(git_output(["status", "--porcelain"], path))))
        entry = {}
    trees.sort(key=lambda tree: tree.timestamp, reverse=True)
    return trees


class ReleaseWorker(QThread):
    finished_releases = Signal(object, object)

    def run(self):
        try:
            self.finished_releases.emit(fetch_releases(), None)
        except (OSError, ValueError, urllib.error.URLError) as error:
            self.finished_releases.emit([], str(error))


class DownloadWorker(QThread):
    finished_install = Signal(str, str)

    def __init__(self, release: Release):
        super().__init__()
        self.release = release

    def run(self):
        release = self.release
        if not release.asset_url or not release.asset_name:
            self.finished_install.emit("", "No build for this platform is attached to that release.")
            return
        settings = read_settings()
        root = Path(settings.get("install_root") or user_data() / "games").expanduser()
        target = root / f"desert-{release.version}"
        try:
            root.mkdir(parents=True, exist_ok=True)
            with tempfile.TemporaryDirectory(prefix="desert-download-") as temp:
                archive = Path(temp) / release.asset_name
                request = urllib.request.Request(release.asset_url, headers={"User-Agent": "Desert-Launcher"})
                with urllib.request.urlopen(request, timeout=60) as response, archive.open("wb") as output:
                    shutil.copyfileobj(response, output)
                staging = Path(temp) / "unpacked"
                staging.mkdir()
                with zipfile.ZipFile(archive) as bundle:
                    base = staging.resolve()
                    for item in bundle.infolist():
                        dest = (staging / item.filename).resolve()
                        if not dest.is_relative_to(base):
                            raise ValueError("The release archive contains an invalid path.")
                    bundle.extractall(staging)
                expected = "Desert.exe" if sys.platform == "win32" else ("Desert" if sys.platform == "darwin" else "Desert.x86_64")
                executable = next((candidate for candidate in staging.rglob(expected) if candidate.is_file()), None)
                if not executable:
                    raise ValueError("The downloaded archive does not contain the expected Desert game build.")
                source = executable.parent
                if sys.platform == "darwin":
                    source = executable.parents[3]
                if target.exists():
                    if not (target / ".desert-install.json").is_file():
                        raise ValueError(f"The target folder already exists and is not a launcher-managed installation: {target}")
                    shutil.rmtree(target)
                shutil.move(str(source), str(target))
                (target / ".desert-install.json").write_text(json.dumps({"version": release.version, "tag": release.tag}, indent=2) + "\n", encoding="utf-8")
            self.finished_install.emit(str(target), "")
        except (OSError, zipfile.BadZipFile, urllib.error.URLError, ValueError) as error:
            self.finished_install.emit("", str(error))


class HeroBanner(QWidget):
    def __init__(self):
        super().__init__()
        self.image = QPixmap(str(resource_path("launcher/assets/desert-storm-banner.jpg")))
        self.setFixedHeight(176)
        self.title = QLabel("DESERT", self)
        self.title.setStyleSheet("color: #f4efe6; font-size: 29px; font-weight: 800; background: transparent;")
        self.subtitle = QLabel("A quiet place in a very large desert.", self)
        self.subtitle.setStyleSheet("color: #e2d8c8; font-size: 13px; background: transparent;")

    def resizeEvent(self, event):
        self.title.move(32, self.height() // 2 - 25)
        self.subtitle.move(34, self.height() // 2 + 14)
        super().resizeEvent(event)

    def paintEvent(self, event):
        painter = QPainter(self)
        if not self.image.isNull():
            target = self.rect()
            ratio = target.width() / max(1, target.height())
            source_height = min(self.image.height(), int(self.image.width() / ratio))
            source_width = min(self.image.width(), int(self.image.height() * ratio))
            source = self.image.rect()
            source.setWidth(source_width)
            source.setHeight(source_height)
            source.moveCenter(self.image.rect().center())
            painter.drawPixmap(target, self.image, source)
        else:
            painter.fillRect(self.rect(), Qt.GlobalColor.black)
        shade = QLinearGradient(0, 0, self.width() * 0.72, 0)
        shade.setColorAt(0.0, QColor(17, 18, 19, 220))
        shade.setColorAt(0.54, QColor(17, 18, 19, 90))
        shade.setColorAt(1.0, QColor(17, 18, 19, 0))
        painter.fillRect(self.rect(), shade)


class Launcher(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle(APP_NAME)
        self.setWindowIcon(QIcon(str(resource_path("launcher/assets/desert-launcher.svg"))))
        self.setMinimumSize(900, 650)
        self.settings = read_settings()
        self.releases: list[Release] = []
        self.release_worker = None
        self.download_worker = None
        self.setStyleSheet("""
            QMainWindow, QWidget { background: #171819; color: #e8e1d5; }
            QLabel#title { font-size: 27px; font-weight: 700; }
            QLabel#subtitle { color: #aaa69d; font-size: 13px; }
            QTabWidget::pane { border: 1px solid #393b3c; border-radius: 8px; }
            QTabBar::tab { background: #232526; color: #aaa69d; padding: 11px 20px; border-top-left-radius: 6px; border-top-right-radius: 6px; }
            QTabBar::tab:selected { background: #34312b; color: #f3bc61; }
            QTableWidget { background: #202223; alternate-background-color: #252728; gridline-color: #383a3b; border: 1px solid #393b3c; border-radius: 6px; }
            QHeaderView::section { background: #2b2d2e; color: #c6c0b5; padding: 8px; border: 0; }
            QComboBox, QLineEdit, QTextBrowser { background: #202223; border: 1px solid #444647; border-radius: 6px; padding: 9px 11px; }
            QTextBrowser { padding: 12px; }
            QPushButton { background: #37393a; border: 1px solid #555657; border-radius: 6px; padding: 9px 14px; }
            QPushButton:hover { background: #47494a; }
            QPushButton#primary { background: #d59a43; color: #171819; border: 0; font-weight: 700; }
            QPushButton#primary:hover { background: #e6aa50; }
            QComboBox::drop-down { border: 0; width: 28px; }
        """)

        center = QWidget()
        outer = QVBoxLayout(center)
        outer.setContentsMargins(0, 0, 0, 0)
        outer.setSpacing(0)
        outer.addWidget(HeroBanner())
        content = QWidget()
        content_layout = QVBoxLayout(content)
        content_layout.setContentsMargins(20, 14, 20, 20)
        content_layout.setSpacing(12)
        self.tabs = QTabWidget()
        self.tabs.addTab(self._play_page(), "Play")
        self.tabs.addTab(self._source_page(), "Source")
        content_layout.addWidget(self.tabs)
        outer.addWidget(content, 1)
        self.setCentralWidget(center)
        self.refresh_releases()
        self.refresh_sources()

    def _play_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(18, 18, 18, 18)
        layout.setSpacing(12)
        top = QHBoxLayout()
        self.release_status = QLabel("Checking for releases…")
        self.refresh_release_button = QPushButton("Refresh")
        self.refresh_release_button.clicked.connect(self.refresh_releases)
        top.addWidget(self.release_status)
        top.addStretch(1)
        top.addWidget(self.refresh_release_button)
        layout.addLayout(top)
        release_line = QHBoxLayout()
        release_line.addWidget(QLabel("Game version"))
        self.release_selector = QComboBox()
        self.release_selector.setMinimumHeight(42)
        self.release_selector.currentIndexChanged.connect(self.show_release_notes)
        release_line.addWidget(self.release_selector, 1)
        layout.addLayout(release_line)
        self.release_meta = QLabel("The newest published version will be selected automatically.")
        self.release_meta.setObjectName("subtitle")
        layout.addWidget(self.release_meta)
        self.release_notes = QTextBrowser()
        self.release_notes.setPlaceholderText("Release notes will appear here.")
        self.release_notes.setOpenExternalLinks(True)
        self.release_notes.setMinimumHeight(165)
        layout.addWidget(self.release_notes, 1)
        self.install_root = QLineEdit(str(self.settings.get("install_root") or user_data() / "games"))
        self.install_root.setReadOnly(True)
        choose_folder = QPushButton("Choose library…")
        choose_folder.clicked.connect(self.choose_install_root)
        install_line = QHBoxLayout()
        install_line.addWidget(QLabel("Install location"))
        install_line.addWidget(self.install_root, 1)
        install_line.addWidget(choose_folder)
        layout.addLayout(install_line)
        self.open_install = QPushButton("Open install folder")
        self.open_install.clicked.connect(lambda: self.open_folder(Path(self.install_root.text())))
        self.play_button = QPushButton("Play")
        self.play_button.setObjectName("primary")
        self.play_button.clicked.connect(self.play_or_install)
        self.install_button = QPushButton("Install latest")
        self.install_button.clicked.connect(self.install_selected)
        self.uninstall_button = QPushButton("Uninstall")
        self.uninstall_button.clicked.connect(self.uninstall_selected)
        actions = QHBoxLayout()
        actions.addWidget(self.open_install)
        actions.addStretch(1)
        actions.addWidget(self.uninstall_button)
        actions.addWidget(self.install_button)
        actions.addWidget(self.play_button)
        layout.addLayout(actions)
        return page

    def _source_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(18, 18, 18, 18)
        layout.setSpacing(10)
        repo_line = QHBoxLayout()
        self.repo_path = QLineEdit(default_repo(self.settings))
        self.repo_path.setPlaceholderText("Choose the Desert repository folder")
        browse = QPushButton("Browse…")
        browse.clicked.connect(self.choose_repo)
        refresh = QPushButton("Refresh")
        refresh.clicked.connect(self.refresh_sources)
        repo_line.addWidget(QLabel("Repository"))
        repo_line.addWidget(self.repo_path, 1)
        repo_line.addWidget(browse)
        repo_line.addWidget(refresh)
        layout.addLayout(repo_line)
        self.source_status = QLabel("Choose a repository to list its worktrees.")
        layout.addWidget(self.source_status)
        filter_line = QHBoxLayout()
        self.source_filter = QLineEdit()
        self.source_filter.setPlaceholderText("Find a branch, worktree, or commit…")
        self.source_filter.textChanged.connect(self.render_sources)
        filter_line.addWidget(self.source_filter, 1)
        self.pin_source = QPushButton("Pin branch")
        self.pin_source.clicked.connect(self.toggle_source_pin)
        filter_line.addWidget(self.pin_source)
        layout.addLayout(filter_line)
        self.source_table = QTableWidget(0, 5)
        self.source_table.setHorizontalHeaderLabels(["Branch / worktree", "Last commit", "Commit message", "Version", "State"])
        self.source_table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        self.source_table.setSelectionMode(QTableWidget.SelectionMode.SingleSelection)
        self.source_table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.source_table.verticalHeader().hide()
        header = self.source_table.horizontalHeader()
        header.setSectionResizeMode(0, QHeaderView.ResizeMode.Interactive)
        header.setSectionResizeMode(1, QHeaderView.ResizeMode.Interactive)
        header.setSectionResizeMode(2, QHeaderView.ResizeMode.Stretch)
        header.setSectionResizeMode(3, QHeaderView.ResizeMode.Interactive)
        header.setSectionResizeMode(4, QHeaderView.ResizeMode.Interactive)
        for column, width in ((0, 210), (1, 140), (3, 110), (4, 150)):
            self.source_table.setColumnWidth(column, width)
        self.source_table.setAlternatingRowColors(True)
        self.source_table.itemSelectionChanged.connect(self.update_source_actions)
        layout.addWidget(self.source_table)
        self.hidden_sources = set(self.settings.get("hidden_sources", []))
        self.pinned_sources = list(self.settings.get("pinned_sources", ["branch:master"]))
        self.show_hidden = QCheckBox("Show hidden worktrees")
        self.show_hidden.toggled.connect(self.refresh_sources)
        layout.addWidget(self.show_hidden)
        note = QLabel("Only checked-out Git worktrees appear here. Branches without a worktree are not playable.")
        note.setObjectName("subtitle")
        layout.addWidget(note)
        self.open_editor = QPushButton("Open editor")
        self.run_game = QPushButton("Run game")
        self.run_game.setObjectName("primary")
        self.open_editor.clicked.connect(lambda: self.launch_source(True))
        self.run_game.clicked.connect(lambda: self.launch_source(False))
        source_actions = QHBoxLayout()
        source_actions.addStretch(1)
        source_actions.addWidget(self.open_editor)
        source_actions.addWidget(self.run_game)
        self.hide_source = QPushButton("Hide selected")
        self.hide_source.clicked.connect(self.hide_selected_source)
        source_actions.insertWidget(0, self.hide_source)
        self.restore_source = QPushButton("Restore selected")
        self.restore_source.clicked.connect(self.restore_selected_source)
        source_actions.insertWidget(1, self.restore_source)
        layout.addLayout(source_actions)
        self.source_rows: list[SourceTree] = []
        return page

    def refresh_releases(self):
        self.release_status.setText("Checking GitHub releases…")
        self.refresh_release_button.setEnabled(False)
        self.release_worker = ReleaseWorker()
        self.release_worker.finished_releases.connect(self.releases_ready)
        self.release_worker.start()

    def releases_ready(self, releases, error):
        self.refresh_release_button.setEnabled(True)
        if error:
            self.release_status.setText(f"Could not reach GitHub: {error}")
            return
        previous_tag = self.selected_release().tag if self.selected_release() else None
        self.releases = releases
        self.release_selector.blockSignals(True)
        self.release_selector.clear()
        for index, release in enumerate(releases):
            latest = " · Latest published" if index == 0 else ""
            self.release_selector.addItem(f"{release.version} — {release.title}{latest}", release.tag)
        selected = self.release_selector.findData(previous_tag) if previous_tag else -1
        self.release_selector.setCurrentIndex(selected if selected >= 0 else (0 if releases else -1))
        self.release_selector.blockSignals(False)
        latest = releases[0].version if releases else ""
        self.release_status.setText(f"Latest published: Desert {latest} · {len(releases)} versions" if latest else "No published game releases found.")
        self.show_release_notes()

    def selected_release(self):
        tag = self.release_selector.currentData()
        return next((release for release in self.releases if release.tag == tag), None)

    def show_release_notes(self):
        release = self.selected_release()
        if release:
            self.release_notes.setMarkdown(release.notes.strip() or "No release notes.")
            installed = installation_for(release.version, installed_games())
            state = "Installed" if installed else ("Available" if release.asset_url else "Unavailable on this platform")
            published = release.published[:10] or "date unknown"
            self.release_meta.setText(f"Published {published}  ·  {state}")
        else:
            self.release_notes.clear()
            self.release_meta.setText("No published game releases found.")
        self.update_play_buttons()

    def update_play_buttons(self):
        release = self.selected_release()
        if not release:
            self.play_button.setText("Play")
            self.play_button.setEnabled(False)
            self.install_button.setEnabled(False)
            self.uninstall_button.setEnabled(False)
            return
        path = installation_for(release.version, installed_games())
        managed = bool(path and (path / ".desert-install.json").is_file())
        self.play_button.setText("Play latest" if release == (self.releases[0] if self.releases else None) else "Play")
        self.play_button.setEnabled(bool(path and game_executable(path)))
        self.install_button.setText(("Update" if managed else "Install a managed copy") if path else ("Install latest" if release == self.releases[0] else "Install"))
        self.install_button.setEnabled(bool(release.asset_url))
        self.uninstall_button.setEnabled(managed)

    def play_or_install(self):
        release = self.selected_release()
        if not release:
            return
        path = installation_for(release.version, installed_games())
        if path:
            executable = game_executable(path)
            if executable:
                try:
                    subprocess.Popen([str(executable)], cwd=path, start_new_session=(sys.platform != "win32"))
                except OSError as error:
                    QMessageBox.critical(self, "Could not start Desert", str(error))
                return
            QMessageBox.warning(self, "Build incomplete", "This installation is missing its game executable. Reinstall it to repair the files.")
        else:
            self.install_selected()

    def install_selected(self):
        release = self.selected_release()
        if not release or not release.asset_url:
            return
        self.install_button.setEnabled(False)
        self.release_status.setText(f"Downloading Desert {release.version}…")
        self.download_worker = DownloadWorker(release)
        self.download_worker.finished_install.connect(self.install_finished)
        self.download_worker.start()

    def install_finished(self, path, error):
        self.install_button.setEnabled(True)
        if error:
            QMessageBox.critical(self, "Installation failed", error)
        else:
            self.release_status.setText(f"Installed Desert {self.selected_release().version if self.selected_release() else ''}.")
            self.refresh_installed_status()

    def refresh_installed_status(self):
        release = self.selected_release()
        if release:
            installed = installation_for(release.version, installed_games())
            state = "Installed" if installed else ("Available" if release.asset_url else "Unavailable on this platform")
            self.release_meta.setText(f"Published {release.published[:10] or 'date unknown'}  ·  {state}")
        self.update_play_buttons()

    def uninstall_selected(self):
        release = self.selected_release()
        folder = installation_for(release.version, installed_games()) if release else None
        if not folder:
            return
        confirm = QMessageBox.question(self, "Uninstall Desert", f"Remove this launcher-managed game folder?\n\n{folder}\n\nYour game saves are kept.")
        if confirm == QMessageBox.StandardButton.Yes:
            try:
                settings = read_settings()
                allowed = {user_data() / "games"}
                allowed.update(Path(root).expanduser() for root in settings.get("install_roots", []))
                allowed.add(Path(settings.get("install_root", str(user_data() / "games"))).expanduser())
                if not any(folder.resolve().parent == root.resolve() for root in allowed):
                    raise ValueError("This build was found in a known folder and is not managed by the launcher.")
                shutil.rmtree(folder)
            except (ValueError, OSError) as error:
                QMessageBox.critical(self, "Could not uninstall", str(error))
                return
            self.refresh_installed_status()

    def choose_install_root(self):
        selected = QFileDialog.getExistingDirectory(self, "Choose game library folder", self.install_root.text())
        if not selected:
            return
        root = Path(selected).expanduser()
        self.install_root.setText(str(root))
        self.settings["install_root"] = str(root)
        roots = set(self.settings.get("install_roots", []))
        roots.add(str(root))
        self.settings["install_roots"] = sorted(roots)
        write_settings(self.settings)

    def open_folder(self, path: Path):
        path.mkdir(parents=True, exist_ok=True)
        if sys.platform == "win32":
            os.startfile(path)  # type: ignore[attr-defined]
        elif sys.platform == "darwin":
            subprocess.Popen(["open", str(path)])
        else:
            subprocess.Popen(["xdg-open", str(path)])

    def choose_repo(self):
        selected = QFileDialog.getExistingDirectory(self, "Choose Desert repository", self.repo_path.text())
        if selected:
            self.repo_path.setText(selected)
            self.refresh_sources()

    def refresh_sources(self):
        repo = Path(self.repo_path.text()).expanduser()
        error_text = ""
        try:
            self.source_rows = list_sources(repo)
            self.settings["repo"] = str(repo)
            write_settings(self.settings)
        except RuntimeError as error:
            self.source_rows = []
            error_text = str(error)
        self.source_error = error_text
        self.render_sources()

    @staticmethod
    def source_identity(tree: SourceTree) -> str:
        if tree.branch.startswith("detached "):
            return f"path:{tree.path}"
        return f"branch:{tree.branch}"

    def visible_sources(self) -> list[SourceTree]:
        query = self.source_filter.text().strip().casefold()
        visible = [tree for tree in self.source_rows if self.show_hidden.isChecked() or str(tree.path) not in self.hidden_sources]
        if query:
            visible = [tree for tree in visible if query in " ".join((tree.branch, tree.path.name, str(tree.path), tree.message, tree.version)).casefold()]
        pin_order = {key: index for index, key in enumerate(self.pinned_sources)}
        visible.sort(key=lambda tree: (
            0 if self.source_identity(tree) in pin_order else 1,
            pin_order.get(self.source_identity(tree), 0),
            -int(tree.timestamp or 0),
            tree.branch.casefold(),
        ))
        return visible

    def render_sources(self):
        current_row = self.source_table.currentRow()
        current_item = self.source_table.item(current_row, 0) if current_row >= 0 else None
        previous_path = current_item.toolTip() if current_item else None
        visible = self.visible_sources()
        repo = Path(self.repo_path.text()).expanduser()
        self.source_table.setRowCount(len(visible))
        for row, tree in enumerate(visible):
            try:
                date = datetime.fromtimestamp(int(tree.timestamp), timezone.utc).astimezone().strftime("%Y-%m-%d %H:%M")
            except (ValueError, OSError):
                date = "Unknown"
            state = "Uncommitted changes" if tree.dirty else "Clean"
            pin = "★ " if self.source_identity(tree) in self.pinned_sources else ""
            values = (f"{pin}{tree.branch} · {tree.path.name}", date, tree.message[:72] + ("…" if len(tree.message) > 72 else ""), tree.version, state)
            for column, value in enumerate(values):
                item = QTableWidgetItem(value)
                item.setToolTip(str(tree.path) if column == 0 else tree.message)
                item.setData(Qt.ItemDataRole.UserRole, row)
                self.source_table.setItem(row, column, item)
        if self.source_error:
            self.source_status.setText(self.source_error)
        elif visible:
            self.source_status.setText(f"{len(visible)} playable worktree(s) in {repo}")
        else:
            self.source_status.setText("No visible playable worktrees found.")
        self.run_game.setEnabled(bool(visible))
        self.open_editor.setEnabled(bool(visible))
        if visible:
            self.source_table.selectRow(0)
            last_path = previous_path or self.settings.get("worktree")
            for row, tree in enumerate(visible):
                if str(tree.path) == last_path:
                    self.source_table.selectRow(row)
                    break
        self.update_source_actions()

    def selected_source(self):
        row = self.source_table.currentRow()
        visible = self.visible_sources()
        return visible[row] if 0 <= row < len(visible) else None

    def hide_selected_source(self):
        tree = self.selected_source()
        if not tree:
            return
        self.hidden_sources.add(str(tree.path))
        self.settings["hidden_sources"] = sorted(self.hidden_sources)
        write_settings(self.settings)
        self.refresh_sources()

    def restore_selected_source(self):
        tree = self.selected_source()
        if not tree:
            return
        self.hidden_sources.discard(str(tree.path))
        self.settings["hidden_sources"] = sorted(self.hidden_sources)
        write_settings(self.settings)
        self.refresh_sources()

    def update_source_actions(self):
        tree = self.selected_source()
        hidden = bool(tree and str(tree.path) in self.hidden_sources)
        pinned = bool(tree and self.source_identity(tree) in self.pinned_sources)
        self.hide_source.setEnabled(bool(tree and not hidden))
        self.restore_source.setEnabled(bool(tree and hidden))
        self.pin_source.setText("Unpin branch" if pinned else "Pin branch")
        self.pin_source.setEnabled(bool(tree))

    def toggle_source_pin(self):
        tree = self.selected_source()
        if not tree:
            return
        identity = self.source_identity(tree)
        if identity in self.pinned_sources:
            self.pinned_sources.remove(identity)
        else:
            self.pinned_sources.append(identity)
        self.settings["pinned_sources"] = self.pinned_sources
        write_settings(self.settings)
        self.render_sources()

    def launch_source(self, editor: bool):
        tree = self.selected_source()
        if not tree:
            return
        settings = read_settings()
        settings["worktree"] = str(tree.path)
        settings["repo"] = self.repo_path.text()
        write_settings(settings)
        godot = settings.get("godot") or shutil.which("godot") or shutil.which("godot4")
        if not godot or not Path(godot).is_file():
            chosen, _ = QFileDialog.getOpenFileName(self, "Choose Godot executable")
            if not chosen:
                return
            godot = chosen
            settings["godot"] = godot
            write_settings(settings)
        command = [godot, "--path", str(tree.path)]
        if editor:
            command.append("--editor")
        try:
            subprocess.Popen(command, cwd=tree.path, start_new_session=(sys.platform != "win32"))
        except OSError as error:
            QMessageBox.critical(self, "Could not start Godot", str(error))


def main() -> int:
    app = QApplication(sys.argv)
    app.setApplicationName("desert-launcher")
    app.setApplicationDisplayName(APP_NAME)
    app.setDesktopFileName("desert-worktree-picker")
    app.setFont(QFont("Noto Sans", 10))
    app.setWindowIcon(QIcon(str(resource_path("launcher/assets/desert-launcher.svg"))))
    window = Launcher()
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())

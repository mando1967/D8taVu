import os
import datetime
import mimetypes
from pathlib import Path
from dataclasses import dataclass
from typing import List, Optional
import shutil
import logging

logger = logging.getLogger(__name__)

@dataclass
class FileInfo:
    name: str
    path: str
    is_dir: bool
    size: int
    modified_time: datetime.datetime
    mime_type: Optional[str] = None
    icon_class: str = "fa-file"

class FileManager:
    def __init__(self, root_path: str, base_url: str = "/D8TAVu/share"):
        """
        Initialize FileManager
        :param root_path: Physical path to the directory
        :param base_url: Base URL for file access
        """
        self.root_path = Path(root_path)
        self.base_url = base_url
        logger.info(f'FileManager initialized with root_path: {root_path}, base_url: {base_url}')

    def check_access(self) -> bool:
        """Check if we can access the root directory"""
        try:
            logger.info(f'Checking access to: {self.root_path}')
            stat_result = self.root_path.stat()
            logger.info(f'Access check successful. Mode: {stat_result.st_mode}')
            return True
        except (PermissionError, OSError) as e:
            logger.error(f'Access check failed: {str(e)}', exc_info=True)
            return False

    def get_safe_path(self, requested_path: str) -> Path:
        """Ensure the requested path is within the root directory"""
        logger.info(f'Getting safe path for: {requested_path}')
        requested_path = requested_path.strip("/")
        full_path = self.root_path / requested_path
        try:
            # Resolve to absolute path and check if it's within root
            real_path = full_path.resolve()
            if not str(real_path).startswith(str(self.root_path)):
                logger.error(f'Access denied: Path outside root directory')
                raise ValueError("Access denied: Path outside root directory")
            logger.info(f'Safe path resolved to: {real_path}')
            return real_path
        except (ValueError, RuntimeError) as e:
            logger.error(f'Error resolving safe path: {str(e)}', exc_info=True)
            raise ValueError("Invalid path")

    def get_mime_type(self, path: Path) -> str:
        """Get MIME type for a file"""
        logger.info(f'Getting MIME type for: {path}')
        mime_type, _ = mimetypes.guess_type(str(path))
        logger.info(f'MIME type resolved to: {mime_type}')
        return mime_type or "application/octet-stream"

    def get_icon_class(self, path: Path, is_dir: bool) -> str:
        """Get Font Awesome icon class based on file type"""
        logger.info(f'Getting icon class for: {path}')
        if is_dir:
            logger.info(f'Icon class resolved to: fa-folder')
            return "fa-folder"
        
        mime_type = self.get_mime_type(path)
        if mime_type:
            if mime_type.startswith("image/"):
                logger.info(f'Icon class resolved to: fa-file-image')
                return "fa-file-image"
            elif mime_type.startswith("video/"):
                logger.info(f'Icon class resolved to: fa-file-video')
                return "fa-file-video"
            elif mime_type.startswith("audio/"):
                logger.info(f'Icon class resolved to: fa-file-audio')
                return "fa-file-audio"
            elif mime_type in ["application/pdf"]:
                logger.info(f'Icon class resolved to: fa-file-pdf')
                return "fa-file-pdf"
            elif mime_type in ["application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]:
                logger.info(f'Icon class resolved to: fa-file-word')
                return "fa-file-word"
            elif mime_type in ["application/vnd.ms-excel", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]:
                logger.info(f'Icon class resolved to: fa-file-excel')
                return "fa-file-excel"
        logger.info(f'Icon class resolved to: fa-file')
        return "fa-file"

    def get_file(self, requested_path: str) -> tuple[Path, str]:
        """Get file path and mime type"""
        logger.info(f'Getting file for: {requested_path}')
        file_path = self.get_safe_path(requested_path)
        if not file_path.is_file():
            logger.error(f'Not a file: {file_path}')
            raise ValueError("Not a file")
        logger.info(f'File resolved to: {file_path}')
        return file_path, self.get_mime_type(file_path)

    def get_download_url(self, path: str) -> str:
        """Get the URL for downloading a file"""
        logger.info(f'Getting download URL for: {path}')
        url = f"{self.base_url}/static/{path.strip('/')}"
        logger.info(f'Download URL resolved to: {url}')
        return url

    def list_directory(self, path: str = "") -> List[FileInfo]:
        """List contents of a directory"""
        try:
            logger.info(f'Listing directory: {path}')
            dir_path = self.get_safe_path(path)
            if not dir_path.is_dir():
                logger.error(f'Path is not a directory: {dir_path}')
                raise ValueError("Not a directory")

            files = []
            for item in dir_path.iterdir():
                try:
                    logger.info(f'Processing entry: {item}')
                    relative_path = str(item.relative_to(self.root_path)).replace("\\", "/")
                    files.append(FileInfo(
                        name=item.name,
                        path=relative_path,
                        is_dir=item.is_dir(),
                        size=item.stat().st_size if item.is_file() else 0,
                        modified_time=datetime.datetime.fromtimestamp(item.stat().st_mtime),
                        mime_type=self.get_mime_type(item) if item.is_file() else None,
                        icon_class=self.get_icon_class(item, item.is_dir())
                    ))
                except Exception as e:
                    logger.error(f'Error processing entry {item}: {str(e)}', exc_info=True)
                    continue

            logger.info(f'Successfully listed {len(files)} entries')
            return sorted(files, key=lambda x: (not x.is_dir, x.name.lower()))
        except Exception as e:
            logger.error(f'Error listing directory: {str(e)}', exc_info=True)
            raise

    def get_breadcrumbs(self, rel_path: str) -> List[tuple]:
        """Generate breadcrumb navigation items"""
        logger.info(f'Getting breadcrumbs for: {rel_path}')
        if not rel_path:
            logger.info(f'Breadcrumbs resolved to: [("Home", "")]')
            return [("Home", "")]

        parts = rel_path.strip("/").split("/")
        breadcrumbs = [("Home", "")]
        current_path = ""

        for part in parts:
            if part:
                current_path = f"{current_path}/{part}" if current_path else part
                breadcrumbs.append((part, current_path))

        logger.info(f'Breadcrumbs resolved to: {breadcrumbs}')
        return breadcrumbs

    def create_directory(self, rel_path: str) -> None:
        """Create a new directory"""
        try:
            logger.info(f'Creating directory: {rel_path}')
            new_dir_path = self.get_safe_path(rel_path)
            new_dir_path.mkdir(parents=True, exist_ok=True)
            logger.info(f'Directory created successfully: {new_dir_path}')
        except ValueError as e:
            logger.error(f'Error creating directory: {str(e)}', exc_info=True)
            raise ValueError(f"Error creating directory: {str(e)}")

    def upload_file(self, rel_path: str, file) -> None:
        """Upload a file to the specified path"""
        try:
            logger.info(f'Uploading file to: {rel_path}')
            file_path = self.get_safe_path(rel_path)
            file.save(str(file_path))
            logger.info(f'File uploaded successfully: {file_path}')
        except ValueError as e:
            logger.error(f'Error uploading file: {str(e)}', exc_info=True)
            raise ValueError(f"Error uploading file: {str(e)}")

    def delete_item(self, rel_path: str) -> None:
        """Delete a file or directory"""
        try:
            logger.info(f'Deleting item: {rel_path}')
            path = self.get_safe_path(rel_path)
            if path.is_dir():
                shutil.rmtree(str(path))
                logger.info(f'Directory deleted successfully: {path}')
            else:
                path.unlink()
                logger.info(f'File deleted successfully: {path}')
        except ValueError as e:
            logger.error(f'Error deleting item: {str(e)}', exc_info=True)
            raise ValueError(f"Error deleting item: {str(e)}")

import argparse
import ctypes
import errno
import os
from pathlib import Path
import pwd
import stat


class Capabilities:
    """Use libcap's descriptor API without reopening a user-controlled pathname."""

    def __init__(self, library):
        self.api = ctypes.CDLL(library, use_errno=True)
        self.api.cap_from_text.argtypes = [ctypes.c_char_p]
        self.api.cap_from_text.restype = ctypes.c_void_p
        self.api.cap_get_fd.argtypes = [ctypes.c_int]
        self.api.cap_get_fd.restype = ctypes.c_void_p
        self.api.cap_set_fd.argtypes = [ctypes.c_int, ctypes.c_void_p]
        self.api.cap_set_fd.restype = ctypes.c_int
        self.api.cap_compare.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
        self.api.cap_compare.restype = ctypes.c_int
        self.api.cap_free.argtypes = [ctypes.c_void_p]
        self.api.cap_free.restype = ctypes.c_int
        self.expected = self.api.cap_from_text(b"cap_sys_nice=p")
        if not self.expected:
            raise OSError(ctypes.get_errno(), "Unable to construct SteamVR capability")

    def matches(self, descriptor):
        current = self.api.cap_get_fd(descriptor)
        if not current:
            code = ctypes.get_errno()
            if code == errno.ENODATA:
                return False
            raise OSError(code, "Unable to read SteamVR launcher capability")
        try:
            comparison = self.api.cap_compare(current, self.expected)
            if comparison < 0:
                raise OSError(ctypes.get_errno(), "Unable to compare SteamVR launcher capability")
            return comparison == 0
        finally:
            self.api.cap_free(current)

    def apply(self, descriptor):
        if self.api.cap_set_fd(descriptor, self.expected) != 0:
            raise OSError(ctypes.get_errno(), "Unable to set SteamVR launcher capability")

    def close(self):
        self.api.cap_free(self.expected)


def open_launcher(path):
    path = Path(path)
    if not path.is_absolute() or ".." in path.parts:
        raise ValueError("SteamVR launcher path must be absolute without parent traversal")
    directory = os.open("/", os.O_PATH | os.O_DIRECTORY)
    try:
        for component in path.parts[1:-1]:
            child = os.open(component, os.O_PATH | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=directory)
            os.close(directory)
            directory = child
        return os.open(path.name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=directory)
    finally:
        os.close(directory)


def apply_capability(path, uid, library):
    try:
        descriptor = open_launcher(path)
    except FileNotFoundError:
        return
    try:
        metadata = os.fstat(descriptor)
        if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != uid:
            raise ValueError("SteamVR launcher must be a regular file owned by the configured user")
        if metadata.st_mode & (stat.S_ISUID | stat.S_ISGID):
            raise ValueError("SteamVR launcher must not be setuid or setgid")
        capabilities = Capabilities(library)
        try:
            if capabilities.matches(descriptor):
                return
            capabilities.apply(descriptor)
            if not capabilities.matches(descriptor):
                raise RuntimeError("SteamVR launcher capability verification failed")
        finally:
            capabilities.close()
    finally:
        os.close(descriptor)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--user", required=True)
    parser.add_argument("--libcap", required=True)
    parser.add_argument("launcher", type=Path)
    args = parser.parse_args()
    apply_capability(args.launcher, pwd.getpwnam(args.user).pw_uid, args.libcap)


if __name__ == "__main__":
    main()

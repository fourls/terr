from pathlib import Path
import tempfile
from typing import Any, Dict, List, Optional
import subprocess
import threading

class Terraria:
    def __init__(
            self,
            path: Path, 
            data_path: Path,
            world_name: str,
            motd: Optional[str] = None,
            players: Optional[int] = None,
            password: Optional[str] = None
        ):
        self.config_path = self._create_config_file({
            "worldpath": data_path.joinpath("worlds"),
            "motd": motd,
            "password": password,
            "players": players,
            "world": data_path.joinpath(f"worlds/{world_name}.wld"),
            "worldname": world_name,
            "autocreate": 1
        })

        self.proc = subprocess.Popen(
            [path, "-config", self.config_path],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )
        self.output_lock = threading.Lock()
        self._output: List[str] = []

        self.output_thread = threading.Thread(target=self._output_thread)
        self.output_thread.start()

    def output(self) -> List[str]:
        self.output_lock.acquire()
        try:
            out = self._output.copy()
        finally:
            self.output_lock.release()
        return out

    def _output_thread(self):
        assert(self.proc.stdout != None)

        line: str = "foo"
        while len(line) > 0:
            line = self.proc.stdout.readline()
            self.output_lock.acquire()
            try:
                self._output.append(line)
            finally:
                self.output_lock.release()

    def _create_config_file(self, config: Dict[str, Any]) -> Path:
        (fid, config_path_str) = tempfile.mkstemp()
        path = Path(config_path_str)

        with open(fid, "w") as f:
            for key in config.keys():
                if config[key] != None:
                    f.write(f"{key}={config[key]}\n")

        return path

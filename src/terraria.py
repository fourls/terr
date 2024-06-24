from pathlib import Path
import tempfile
from typing import Any, Dict, List, Optional
import subprocess
import threading
import time

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

    def output(self, max: Optional[int] = None) -> List[str]:
        with self.output_lock:
            if max != None:
                return self._output[-max:]
            else:
                return self._output.copy()
        
    def send(self, cmd: str):
        assert(self.proc.stdin != None)
        self.proc.stdin.write(cmd + "\r\n")
        self.proc.stdin.flush()

    def exit(self):
        self.send("exit")
        try:
            self.proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self.proc.kill()
            time.sleep(0.3)

    def wait(self):
        self.proc.wait()
        
    def running(self) -> bool:
        return self.proc.poll() == None

    def _output_thread(self):
        assert(self.proc.stdout != None)

        line: str = "foo"
        while len(line) > 0:
            line = self.proc.stdout.readline()
            with self.output_lock:
                self._output.append(line)

    def _create_config_file(self, config: Dict[str, Any]) -> Path:
        (fid, config_path_str) = tempfile.mkstemp()
        path = Path(config_path_str)

        with open(fid, "w") as f:
            for key in config.keys():
                if config[key] != None:
                    f.write(f"{key}={config[key]}\n")

        return path

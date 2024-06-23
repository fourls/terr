from flask import Flask, render_template
from terraria import Terraria
from pathlib import Path

app = Flask(__name__)
app.run()

base_path = Path(__file__).parent.parent.resolve()
terraria = Terraria(
    base_path.joinpath("server/launch.sh"),
    data_path=base_path.joinpath("data"),
    world_name="TestWorld",
    password="barbaz",
    motd="yooo whatsuppp!!!"
)

@app.route("/")
def get_logs():
    return render_template("logs.html", logs=terraria.output())
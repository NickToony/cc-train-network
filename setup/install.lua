local h = fs.open("startup", "w");h.write(http.get("https://db.tt/gDAuIInu").readAll());h.close();shell.run("reboot");
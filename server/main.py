#!/usr/bin/env python3
"""
GameZero Dedicated Backend Service
Fornece REST API para:
- Handshake de versão e release notes (/api/v1/version)
- Autenticação e contas de usuário (/api/v1/auth/*)
- Gerenciamento de multi-personagens (/api/v1/characters/*)
- Sincronização em nuvem do estado de equipamentos e mochila
"""

import sys
import os
import json
import argparse
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# Importa o módulo de banco de dados
sys.path.insert(0, os.path.dirname(__file__))
import database

VERSION_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), "version.json")

class GameZeroAPIHandler(BaseHTTPRequestHandler):
    def _send_json(self, status_code, data):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()

    def _read_body_json(self):
        try:
            content_length = int(self.headers.get("Content-Length", 0))
            if content_length > 0:
                raw = self.rfile.read(content_length).decode("utf-8")
                return json.loads(raw)
        except Exception:
            pass
        return {}

    def _get_auth_account(self):
        auth_header = self.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            token = auth_header[7:].strip()
            return database.get_account_from_token(token)
        return None

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")

        # 1. Version Handshake & Release Notes
        if path == "/api/v1/version":
            if os.path.exists(VERSION_FILE):
                with open(VERSION_FILE, "r", encoding="utf-8") as f:
                    ver_data = json.load(f)
                self._send_json(200, {"success": True, "data": ver_data})
            else:
                self._send_json(200, {
                    "success": True,
                    "data": {
                        "client_version": "0.5.0",
                        "min_required_version": "0.5.0",
                        "patch_notes": {"title": "GameZero", "highlights": []}
                    }
                })
            return

        # 2. List Characters for Account
        if path == "/api/v1/characters":
            acc = self._get_auth_account()
            if not acc:
                self._send_json(401, {"success": False, "error": "Sessão inválida ou expirada."})
                return
            chars = database.get_characters(acc["id"])
            self._send_json(200, {"success": True, "characters": chars, "username": acc["username"]})
            return

        # 3. Get Full Character Details
        if path.startswith("/api/v1/characters/"):
            char_id = path.split("/")[-1]
            acc = self._get_auth_account()
            if not acc:
                self._send_json(401, {"success": False, "error": "Sessão inválida."})
                return
            char_full = database.get_character_full(char_id)
            if not char_full or char_full.get("account_id") != acc["id"]:
                self._send_json(404, {"success": False, "error": "Personagem não encontrado."})
                return
            self._send_json(200, {"success": True, "character": char_full})
            return

        # Health Check
        if path == "" or path == "/health":
            self._send_json(200, {"status": "online", "service": "GameZero API Server v0.5.0"})
            return

        self._send_json(404, {"success": False, "error": "Rota não encontrada."})

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")
        body = self._read_body_json()

        # 1. Register
        if path == "/api/v1/auth/register":
            username = body.get("username", "")
            password = body.get("password", "")
            ok, res = database.register_account(username, password)
            if ok:
                # Faz login automático após registro
                _, login_res = database.login_account(username, password)
                self._send_json(201, {"success": True, "message": "Conta criada!", "session": login_res})
            else:
                self._send_json(400, {"success": False, "error": res})
            return

        # 2. Login
        if path == "/api/v1/auth/login":
            username = body.get("username", "")
            password = body.get("password", "")
            ok, res = database.login_account(username, password)
            if ok:
                self._send_json(200, {"success": True, "session": res})
            else:
                self._send_json(401, {"success": False, "error": res})
            return

        # 3. Create Character
        if path == "/api/v1/characters":
            acc = self._get_auth_account()
            if not acc:
                self._send_json(401, {"success": False, "error": "Sessão inválida."})
                return
            name = body.get("name", "")
            class_id = body.get("class_id", "")
            ok, res = database.create_character(acc["id"], name, class_id)
            if ok:
                self._send_json(201, {"success": True, "character": res})
            else:
                self._send_json(400, {"success": False, "error": res})
            return

        # 4. Sync / Save Full Character State
        if path.startswith("/api/v1/characters/") and path.endswith("/save"):
            parts = path.split("/")
            char_id = parts[-2]
            acc = self._get_auth_account()
            if not acc:
                self._send_json(401, {"success": False, "error": "Sessão inválida."})
                return
            ok, res = database.save_character_full(acc["id"], char_id, body)
            if ok:
                self._send_json(200, {"success": True, "message": res})
            else:
                self._send_json(400, {"success": False, "error": res})
            return

        self._send_json(404, {"success": False, "error": "Rota não encontrada."})

    def do_DELETE(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")
        if path.startswith("/api/v1/characters/"):
            char_id = path.split("/")[-1]
            acc = self._get_auth_account()
            if not acc:
                self._send_json(401, {"success": False, "error": "Sessão inválida."})
                return
            ok, res = database.delete_character(acc["id"], char_id)
            if ok:
                self._send_json(200, {"success": True, "message": res})
            else:
                self._send_json(400, {"success": False, "error": res})
            return
        self._send_json(404, {"success": False, "error": "Rota não encontrada."})

def run(port=8088):
    database.init_db()
    server_address = ("0.0.0.0", port)
    httpd = HTTPServer(server_address, GameZeroAPIHandler)
    print(f"🚀 GameZero Dedicated Server ativo em http://0.0.0.0:{port}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Servidor encerrado.")
        httpd.server_close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="GameZero Backend API Server")
    parser.add_argument("--port", type=int, default=8088, help="Porta do servidor (padrão: 8088)")
    args = parser.parse_args()
    run(args.port)

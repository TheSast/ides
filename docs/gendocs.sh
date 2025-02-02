#!/usr/bin/env bash
cp $(nix-build docs.nix --no-out-link) docs.md

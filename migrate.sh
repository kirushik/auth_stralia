#!/bin/sh
mix run --eval "Ecto.Migrator.run(AuthStralia.Storage.DB,\"db/migrations\",:up,%{all: true})"

#!/usr/bin/env bash

mix format && mix test && mix credo && git status

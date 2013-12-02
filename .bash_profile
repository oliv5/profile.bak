#!/bin/bash
# ~/.bash_profile: executed by bash(1) for login shells.
# Loads .profile since it is skipped when .bash_profile exists.

# Load .profile
[[ -r ~/.profile ]] && . ~/.profile

# Load .bashrc
[[ -r ~/.bashrc ]] && . ~/.bashrc

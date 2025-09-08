#!/bin/bash
git checkout dev
git add .
git commit
git push origin
git checkout main
git merge origin/dev
git push origin
git checkout dev
#!/bin/bash
# List scratchpads with toggle and close options

hyprctl clients -j | jq -r '
  .[] | select(.workspace.name | startswith("special:")) |
  "toggle|\(.workspace.name | sub("special:";""))|\(.address)| \(.workspace.name | sub("special:";"")) - \(.class) [\(.title[:40])]",
  "close|\(.workspace.name | sub("special:";""))|\(.address)|󰅖 Close: \(.workspace.name | sub("special:";"")) - \(.class)"
' | rofi -dmenu -p "Scratchpads" -i | {
  IFS="|" read action name addr _
  [ -z "$action" ] && exit
  if [ "$action" = "close" ]; then
    hyprctl dispatch closewindow "address:$addr"
  else
    pypr toggle "$name"
  fi
}

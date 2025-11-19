if os.getenv("GIT_WORK_TREE") == nil then
  return LazyVim.root.git()
else
  return os.getenv("GIT_WORK_TREE")
end

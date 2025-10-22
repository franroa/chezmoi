function nvim-kube-fix
    # The first argument ($argv[1]) is the path to the temporary file.

    # This sed command is a direct translation but may not be the most reliable.
    sed -i -E 's/(\s+config\.alloy:\s)".*"/echo -e "\1"/g' "$argv[1]"

    # Open the file with nvim.
    nvim "$argv[1]"
end

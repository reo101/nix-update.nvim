if vim.g.loaded_nix_update == 1 then
  return
end

vim.g.loaded_nix_update = 1

require("nix-update.commands").register()

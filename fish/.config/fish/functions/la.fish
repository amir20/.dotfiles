# Defined in - @ line 1
function la --wraps='exa -abghl --git' --description 'alias la=exa -abghl --git'
  exa --group-directories-first -abghl --git $argv;
end

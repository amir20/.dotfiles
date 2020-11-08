# Defined in - @ line 1
function ll --wraps='exa -lg' --description 'alias ll=exa -lg'
  exa --group-directories-first -lg $argv;
end

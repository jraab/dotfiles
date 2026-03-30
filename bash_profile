# ~/.bash_profile - Login shell configuration

# Disable bell
bind 'set bell-style none' 2>/dev/null

# Source .bashrc for interactive settings
if [[ -f ~/.bashrc ]]; then
    source ~/.bashrc
fi

# Conda - check common install locations
for conda_sh in \
    "$HOME/miniconda3/etc/profile.d/conda.sh" \
    "$HOME/anaconda3/etc/profile.d/conda.sh"; do
    if [[ -f "$conda_sh" ]]; then
        source "$conda_sh"
        break
    fi
done

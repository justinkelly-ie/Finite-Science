for f in 'Algebraic Calculus'* 'Maxel algebra'* 'MF'* 'Relativistic velocity'* 'Solving a quadratic'* 'The algebra'* 'The Factor'* 'Visualizing decimal'*; do
    # Try to find a number following MF, Math Foundation(s), or at the end
    num=$(echo "$f" | grep -oP '(MF|Math Foundation|Math Foundations) \K[0-9]+' || echo "$f" | grep -oP '(MF|Math Foundations)\K[0-9]+' || echo "$f" | grep -oP ' \K[0-9]+(?= \[)')
    
    if [ -n "$num" ]; then
        padded_num=$(printf "%03d" "$num")
        mv "$f" "${padded_num} - ${f}"
        echo "Fixed: $f"
    fi
done


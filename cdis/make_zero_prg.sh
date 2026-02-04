# starts with basic and then all zeros
(printf '\x01\x08'; dd if=/dev/zero bs=1 count=2046 2>/dev/null)

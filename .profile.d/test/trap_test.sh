#!/bin/bash

initial_trap='echo "messy" ;'" echo 'handler'"
non_f_trap='echo "non-function trap"'
f_trap() {
  echo "function trap"
}

print_status() {
  echo "    SIGINT  trap: `trap-get SIGINT`"  
  echo "    SIGTERM trap: `trap-get SIGTERM`"
  echo "-------------"
  echo
}

echo "--- TEST START ---"
echo "Initial trap state (should be empty):"
print_status

echo 'Setting messy non-function handler for SIGINT ("original state")'
trap "$initial_trap" SIGINT
print_status

echo 'Pop empty stacks (still in original state)'
trap-pop SIGINT SIGTERM
print_status

echo 'Push non-function handler for SIGINT'
trap-push "$non_f_trap" SIGINT
print_status

echo 'Append function handler for SIGINT and SIGTERM'
trap-append f_trap SIGINT SIGTERM
print_status

echo 'Prepend function handler for SIGINT and SIGTERM'
trap-prepend f_trap SIGINT SIGTERM
print_status

echo 'Push non-function handler for SIGINT and SIGTERM'
trap-push "$non_f_trap" SIGINT SIGTERM
print_status

echo 'Pop both stacks'
trap-pop SIGINT SIGTERM
print_status

echo 'Prepend function handler for SIGINT and SIGTERM'
trap-prepend f_trap SIGINT SIGTERM
print_status

echo 'Pop both stacks thrice'
trap-pop SIGINT SIGTERM
trap-pop SIGINT SIGTERM
trap-pop SIGINT SIGTERM
print_status

echo 'Push non-function handler for SIGTERM'
trap-push "$non_f_trap" SIGTERM
print_status

echo 'Pop handler state for SIGINT (SIGINT is now back to original state)'
trap-pop SIGINT
print_status

echo 'Pop handler state for SIGTERM (SIGTERM is now back to original state)'
trap-pop SIGTERM
print_status

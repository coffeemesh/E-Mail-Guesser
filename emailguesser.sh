#!/usr/bin/env sh

get_input() {
    printf "Enter the first name, surname, and domain (comma-separated or space-separated),\nor press Enter to input separately: "
    IFS= read -r user_input
    user_input=$(printf '%s' "$user_input" | sed 's/^ *//;s/ *$//')

    if [ -n "$user_input" ]; then
        if printf '%s' "$user_input" | grep -q ','; then
            name=$(printf '%s' "$user_input" | cut -d',' -f1 | sed 's/^ *//;s/ *$//')
            surname=$(printf '%s' "$user_input" | cut -d',' -f2 | sed 's/^ *//;s/ *$//')
            domain=$(printf '%s' "$user_input" | cut -d',' -f3 | sed 's/^ *//;s/ *$//')
        else
            set -- $user_input
            name=${1:-}
            surname=${2:-}
            domain=${3:-}
        fi
    else
        printf "Enter the first name: "
        IFS= read -r name
        printf "Enter the surname: "
        IFS= read -r surname
        printf "Enter the domain without @ symbol: "
        IFS= read -r domain
    fi

    name=$(printf '%s' "$name" | sed 's/^ *//;s/ *$//')
    surname=$(printf '%s' "$surname" | sed 's/^ *//;s/ *$//')
    domain=$(printf '%s' "$domain" | sed 's/^ *//;s/^@//;s/ *$//')
}

generate_combinations() {
    combinations=''

    add_combination() {
        case ",$combinations," in
            *,"$1",*) ;;
            *) combinations=${combinations:+$combinations,}$1 ;;
        esac
    }

    add_combination "${name}@${domain}"
    add_combination "$(printf '%.3s' "$name")@${domain}"
    add_combination "${surname}@${domain}"
    add_combination "$(printf '%.3s' "$surname")@${domain}"

    for separator in '' '.' '-'; do
        add_combination "${name}${separator}${surname}@${domain}"
        add_combination "$(printf '%.1s' "$name")${separator}${surname}@${domain}"

        i=1
        while [ "$i" -lt 4 ]; do
            add_combination "$(printf '%.1s' "$name")${separator}$(printf "%.${i}s" "$surname")@${domain}"
            i=$((i + 1))
        done

        i=1
        while [ "$i" -lt 3 ]; do
            add_combination "$(printf "%.${i}s" "$name")${separator}$(printf '%.1s' "$surname")@${domain}"
            i=$((i + 1))
        done

        add_combination "${surname}${separator}${name}@${domain}"
        add_combination "$(printf '%.1s' "$surname")${separator}${name}@${domain}"

        i=1
        while [ "$i" -lt 4 ]; do
            add_combination "$(printf '%.1s' "$surname")${separator}$(printf "%.${i}s" "$name")@${domain}"
            i=$((i + 1))
        done

        i=1
        while [ "$i" -lt 3 ]; do
            add_combination "$(printf "%.${i}s" "$surname")${separator}$(printf '%.1s' "$name")@${domain}"
            i=$((i + 1))
        done
    done
}

while true; do
    get_input

    if [ -z "$name" ] || [ -z "$surname" ] || [ -z "$domain" ]; then
        printf "All fields are required. Please try again.\n\n"
        continue
    fi

    generate_combinations

    count=$(printf '%s' "$combinations" | tr ',' '\n' | sed '/^$/d' | sort -u | wc -l | tr -d ' ')
    sorted_combinations=$(printf '%s' "$combinations" | tr ',' '\n' | sed '/^$/d' | sort -u)

    printf "\nDo you want to display the results in the console or save to a file? (C/F): "
    IFS= read -r output_choice
    output_choice=$(printf '%s' "$output_choice" | tr '[:upper:]' '[:lower:]')

    case "$output_choice" in
        c)
            printf "Total combinations: %s\n" "$count"
            printf '%s\n' "$sorted_combinations" | paste -sd ',' -
            printf "\nPress Enter to exit..."
            IFS= read -r _
            exit 0
            ;;
        f)
            timestamp=$(date '+%H-%M_%d_%m_%y')
            filename="emails_${timestamp}.txt"
            {
                printf "Total combinations: %s\n" "$count"
                printf '%s\n' "$sorted_combinations" | paste -sd ',' -
                printf '\n'
            } > "$filename"

            printf "Combinations saved to %s\n" "$(cd "$(dirname "$filename")" && pwd)/$(basename "$filename")"

            case "$(uname -s)" in
                Darwin*) open "$filename" ;;
                Linux*) command -v xdg-open >/dev/null 2>&1 && xdg-open "$filename" >/dev/null 2>&1 & ;;
            esac
            exit 0
            ;;
        *)
            printf "Invalid choice. Please enter 'C' for a console output or 'F' for a file output.\n"
            ;;
    esac
done

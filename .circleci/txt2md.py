"""This script generates README.md based on s3_list.txt."""

TXT_FILENAME = "processed/s3_list.txt"
MD_FILENAME = "processed/README.md"

def get_md_name(s3_name):
    """Return the filename with leading bullet list MD format."""

    path_tokens = s3_name.rstrip('/').split('/')
    indentation_level = len(path_tokens)
    list_prefix = indentation_level * 2 * ' ' + '* '
    file_basename = path_tokens[-1]
    if s3_name.endswith('/'):
        return list_prefix + file_basename
    else:
        bucket_url = "https://cimr-d.s3.amazonaws.com"
        return f"{list_prefix}[{file_basename}]({bucket_url}/{s3_name})"


with open(TXT_FILENAME) as file_in, open(MD_FILENAME, 'w') as file_out:
    file_out.write("List of processed files (with links to AWS S3 bucket):\n")
    file_out.write("----\n")
    for line_in in file_in:
        tokens = line_in.split()
        s3_date = tokens[0] + " " + tokens[1]
        s3_size = tokens[2] + " " + tokens[3]
        s3_name = " ".join(tokens[4:])
        md_name = get_md_name(s3_name)

        if s3_name.endswith('/'):
            # Do not show size and date fields for a directory
            file_out.write(md_name + '\n')
        else:
            # For a regular file, includes size and date fields too
            size_str = ": " + s3_size
            date_str = f" (updated on *{s3_date}*)"
            file_out.write(md_name + size_str + date_str + '\n')

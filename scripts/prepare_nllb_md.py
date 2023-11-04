import argparse, os
from pathlib import Path
from match_file_lines import main as match_file_lines
from sort_file import main as sort_file

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-folder", required=True)
    parser.add_argument("--output-folder", required=True)
    return parser.parse_args()

def extract_prefix(name_extract:str) -> str:
    extract_array = name_extract.split('.')
    if len(extract_array) > 0:
        return extract_array[0]
    return ""

def generate_english_file(current_file):
    extract_array = current_file.split('.')
    if len(extract_array) > 0:
        extract_array[len(extract_array)-1] = "eng_Latn"
        return '.'.join(extract_array)
    return ""

def main(args):
    eng_language = "eng_Latn"
    output_folder_order = f"{args.output_folder}/order_files"
    output_folder_reordered = f"{args.output_folder}/reordered"
    sub_folders = os.scandir(args.input_folder)
    print(f"Starting : \\n")
    for sub_folder in sub_folders:
        sub_folder_full_path = f"{args.input_folder}/{sub_folder.name}"
        reference_folder = f"{args.output_folder}/{sub_folder.name}"
        files = os.listdir(sub_folder_full_path)
        #print(f"Current Folder : {sub_folder_full_path}")
        for current_file in files:
            #print(f"Current file is: {current_file}")
            prefix = extract_prefix(current_file)
            if not current_file.endswith(eng_language):
                
                current_file_english = generate_english_file(current_file)
                args.input_files = [
                    f"{reference_folder}/reference/{prefix}.{eng_language}",
                    f"{sub_folder_full_path}/{current_file_english}"
                ]
                args.output_files = [
                    f"{output_folder_order}/{sub_folder.name}/reference-{prefix}.{eng_language}.order.txt",
                    f"{output_folder_order}/{sub_folder.name}/{current_file}.order.txt"
                ]
                #print(f"Preparing the match for order: \\n---> Input files {args.input_files}\\n---> Output Files: {args.output_files}")
                match_command = f"python scripts/match_file_lines.py {args.input_files[0]} {args.input_files[1]} --output-files {args.output_files[0]} {args.output_files[1]}"
                print(match_command)
                #match_file_lines(args); 
                for current_lang_file in [current_file_english, current_file]:
                    
                    args.input_file = f"{sub_folder_full_path}/{current_lang_file}"
                    args.order_file = f"{args.output_files[1]}"
                    args.output_file = f"{output_folder_reordered}/{sub_folder.name}/{prefix}/{current_lang_file}"
                    #print(f"Sorting the files -  Input:[{args.input_file}], Order:[{args.order_file}], Output:[{args.output_file}] ")
                    sort_command = f"python scripts/sort_file.py --input-file {args.input_file} --order-file {args.order_file} --output-file {args.output_file}"
                    #sort_file(args)
                    print(sort_command)
    print("\\ncompleted")

            
if __name__ == '__main__':
    args = parse_args()
    main(args)
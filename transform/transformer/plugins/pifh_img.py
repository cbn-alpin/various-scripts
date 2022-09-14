import click
import csv
import datetime
import glob
import hashlib
import os
import re
import shutil
import json

import pyexiv2

from helpers.config import Config
from helpers.helpers import print_msg, print_info, print_error, print_verbose


class PifhImg:
    def __init__(self, input_file, output_file):
        self.input = input_file
        self.output = output_file
        self.filename_pattern = re.compile(
            r"""
            ^
            ([0-9]+)
            _(.+?)
            _([A-Za-zéç -]+[_ ][A-Za-zéç-]+|Anonyme_0)
            _(ALIZARI|Aucun|CBNA|cbna|CBNMC|cbnmc|CBNMED|CEN|CSA|DREAL|sbf)
            (?:[_-]([^.]+))?
            (?:\.[Jj][Pp][Ee]?[Gg]){1,2}
            $
            """,
            re.VERBOSE,
        )
        self.unduplicates = []
        self.authors = []
        self.organisms = []
        self.files_nbr = 0
        self.jpg_nbr = 0
        self.match_nbr = 0
        self.duplicate_nbr = 0
        self.not_match_nbr = 0
        self.csv_write_row_nbr = 0

        self._set_ouput_fieldnames()
        self._register_dialect()
        self._open_output_csv()

    def _set_ouput_fieldnames(self):
        self.output_fieldnames = [
            "cd_ref",
            "title",
            "url",
            "author",
            "description",
            "date",
            "source",
            "licence",
        ]

    def _register_dialect(self):
        csv.register_dialect(
            "tsv",
            delimiter="\t",
            quotechar='"',
            doublequote=True,
            quoting=csv.QUOTE_MINIMAL,
            # quoting=csv.QUOTE_NONE,
            # escapechar='\\',
            escapechar="",
            lineterminator="\n",
        )

    def _open_output_csv(self):
        self.csv_handle = open(self.output, "w", newline="", encoding="utf-8")

        self.writer = csv.DictWriter(
            self.csv_handle, dialect="tsv", fieldnames=self.output_fieldnames
        )
        self.writer.writeheader()

    def __del__(self):
        self.csv_handle.close()

    def run(self):
        for self.filepath in glob.iglob(self.input + "/**/*.*", recursive=True):
            filename = os.path.basename(self.filepath)
            self.filename = self._clean_filename(filename)
            ext = os.path.splitext(self.filename)[1]
            if re.match(r"^\.jpe?g$", ext, re.IGNORECASE):
                self.jpg_nbr += 1
                infos = self._extract_infos(self.filename)
                self._copy_file(infos)
            else:
                print_error(f"Not JPEG file: {self.filename}")
            self.files_nbr += 1
        self._print_summary()

    def _extract_infos(self, filename):
        print(filename)
        match = self.filename_pattern.search(filename)
        infos = None
        if match:
            self.match_nbr += 1

            md5 = self._md5()
            infos = {
                "md5": md5,
                "md5_path": self._split_md5_in_directory(md5),
                "cd_nom": match.group(1),
                "species": self._clean_value(match.group(2)),
                "author": self._clean_author(match.group(3)),
                "organism": self._clean_organism(match.group(4)),
                "id": self._clean_value(match.group(5)),
            }
            #print(infos)

            self._distinct_infos(infos)

            if (infos['md5'] not in self.unduplicates):
                self.unduplicates.append(infos['md5'])
                self.csv_write_row_nbr += 1
                new_row = {
                    "cd_ref": infos["cd_nom"],
                    "title": infos["species"],
                    "url": self._build_url(infos),
                    "author": infos["author"],
                    "description": self._build_description(infos),
                    "date": self._get_date_taken(),
                    "source": f"{infos['organism']}",
                    "licence": self._build_licence(infos),
                }
                self._write_row(filename, new_row)
            else:
                self.duplicate_nbr += 1
                print_error(f"Duplicate file: {self.filename}")
        else:
            self.not_match_nbr += 1
            print_error(f"Filename NOT match: {filename}")

        return infos

    def _md5(self):
        hash_md5 = hashlib.md5()
        with open(self.filepath, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()

    def _split_md5_in_directory(self, md5, level=4, step=2):
        path = []
        start = 0
        end = level * step
        for i in range(start, end, step):
            path.append(md5[i : i + step])
        path.append(md5[end:])
        return "/".join(path)

    def _clean_author(self, author):
        substitutes = Config.get('substitutes.authors')
        author = "ANONYME" if author == None else self._clean_value(author)
        return (substitutes[author] if author in substitutes else author)

    def _clean_value(self, value):
        return value.replace("_", " ") if value else ""

    def _clean_organism(self, organism):
        substitutes = {
            "AUCUN": "INCONNU",
            "CBNA": "CBNA (PIFH)",
        }
        organism = "INCONNU" if organism == None else organism.upper()
        return (substitutes[organism] if organism in substitutes else organism)

    def _get_date_taken(self):
        metadata = pyexiv2.ImageMetadata(self.filepath)
        metadata.read()

        meta_date = None
        if 'Exif.Photo.DateTimeOriginal' in metadata:
            meta_date = metadata['Exif.Photo.DateTimeOriginal']
        elif 'Exif.Image.DateTimeOriginal' in metadata:
            meta_date = metadata['Exif.Image.DateTimeOriginal']

        formated_date = "\\N"
        if meta_date:
            date = meta_date.value
            if isinstance(date, str):
                print(f"\tDate str: {date}")
                if re.match(r'[12][90][0-9]{2}:[0-9]{2}:[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}', date):
                    formated_date = datetime.datetime.strptime(date, '%Y:%m:%d %H:%M:%S')
                    print_info(f"\tDate str formated: {formated_date}")
                else:
                    print_error(f"\tDate str not match: '{date}' !")
            elif isinstance(date, datetime.datetime) :
                formated_date = date.strftime("%Y-%m-%d %H:%M:%S")
                print_info(f"\tDate datetime formated: {formated_date}")
            else:
                print_error(f"Date type '{type(date)}' not match for {self.filepath} !")
        print(f"\tDate formated: {formated_date}")
        return formated_date

    def _distinct_infos(self, infos):
        if infos["author"] not in self.authors:
            self.authors.append(infos["author"])
        if infos["organism"] not in self.organisms:
            self.organisms.append(infos["organism"])

    def _build_url(self, infos):
        url_base = f"https://img.biodiversite-aura.fr"
        url = f"{url_base}/{infos['organism'].split()[0].lower()}/{infos['md5_path']}.jpg"
        return url

    def _build_description(self, infos):
        description = []
        if infos['id']:
            description.append(f"Notes : {infos['id']}")
        description.append(f"MD5 : {infos['md5']}")
        description.append(f"Fichier : {self.filename}")
        return ' ; '.join(description)

    def _build_licence(self, infos):
        licence = "CC BY-NC-ND"
        if infos['organism'].split()[0].lower() == 'cbna':
            licence = "CC BY-NC-SA"
        return licence

    def _write_row(self, filename, row):
        try:
            self.writer.writerow(row)
        except csv.Error as e:
            sys.exit(f"Error for file {filename}: {e}")

    def _copy_file(self, infos):
        if infos:
            src = self.filepath
            dst = os.path.dirname(self.output) + "/" + infos['organism'].lower() + "/" + infos["md5_path"] + '.jpg'
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(src, dst)

    def _print_summary(self):
        self.authors.sort()
        print(f"Authors: {json.dumps(self.authors, indent=4, ensure_ascii=False)}")
        self.organisms.sort()
        print(f"Organims: {json.dumps(self.organisms, indent=4, ensure_ascii=False)}")
        print_info(f"Number of JPEG finded: {self.jpg_nbr} jpg / {self.files_nbr} files")
        print_info(f"Number of file name NOT matched: {self.not_match_nbr} / {self.match_nbr}")
        print_info(f"Number of file name DUPLICATED:  {self.duplicate_nbr}")
        print_info(f"Number of output CSV row writed: {self.csv_write_row_nbr} / {self.files_nbr}")

    def _clean_filename(self, filename):
        substitutes = Config.get('substitutes.filenames')
        return (substitutes[filename] if filename in substitutes else filename)

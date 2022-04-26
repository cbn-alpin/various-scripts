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

        self.authors = []
        self.organisms = []
        self.files_nbr = 0
        self.jpg_nbr = 0
        self.match_nbr = 0
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
            filename = self._clean_filename(filename)
            ext = os.path.splitext(filename)[1]
            if re.match(r"^\.jpe?g$", ext, re.IGNORECASE):
                self.jpg_nbr += 1
                infos = self._extract_infos(filename)
                self._copy_file(infos)
            else:
                print_error(f"Not JPEG file: {filename}")
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

            if infos["organism"] and infos["organism"] != "CBNA":
                self.csv_write_row_nbr += 1
                new_row = {
                    "cd_ref": infos["cd_nom"],
                    "title": infos["species"],
                    "url": self._build_url(infos),
                    "author": infos["author"],
                    "description": self._build_description(infos),
                    "date": self._get_date_taken(),
                    "source": f"{infos['organism']}",
                    "licence": "CC BY-NC-ND",
                }
                self._write_row(filename, new_row)
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
        substitutes = {"AUCUN": "INCONNU"}
        organism = "INCONNU" if organism == None else organism.upper()
        return (substitutes[organism] if organism in substitutes else organism)

    def _get_date_taken(self):
        metadata = pyexiv2.ImageMetadata(self.filepath)
        metadata.read()

        date = None
        if 'Exif.Photo.DateTimeOriginal' in metadata:
            date = metadata['Exif.Photo.DateTimeOriginal']
        elif 'Exif.Image.DateTimeOriginal' in metadata:
            date = metadata['Exif.Image.DateTimeOriginal']

        formated_date = "\\N"
        if date:
            formated_date = date.value.strftime("%Y-%m-%d %H:%M:%S")
        return formated_date

    def _distinct_infos(self, infos):
        if infos["author"] not in self.authors:
            self.authors.append(infos["author"])
        if infos["organism"] not in self.organisms:
            self.organisms.append(infos["organism"])

    def _build_url(self, infos):
        url_base = f"https://img.biodiversite-aura.fr"
        url = f"{url_base}/{infos['organism'].lower()}/{infos['md5_path']}.jpg"
        return url

    def _build_description(self, infos):
        description = []
        if infos['id']:
            description.append(f"Notes : {infos['id']}")
        description.append(f"MD5 : {infos['md5']}")
        return ' ; '.join(description)


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
        print(f"Authors: {json.dumps(self.authors, indent=4)}")
        self.organisms.sort()
        print(f"Organims: {json.dumps(self.organisms, indent=4)}")
        print_info(f"Number of JPEG finded: {self.jpg_nbr} jpg / {self.files_nbr} files")
        print_info(f"Number of file name NOT matched: {self.not_match_nbr} / {self.match_nbr}")
        print_info(f"Number of output CSV row writed: {self.csv_write_row_nbr} / {self.files_nbr}")

    def _clean_filename(self, filename):
        substitutes = Config.get('substitutes.filenames')
        return (substitutes[filename] if filename in substitutes else filename)

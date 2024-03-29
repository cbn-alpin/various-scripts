import click
import csv
import datetime
import re

from helpers.config import Config
from helpers.helpers import print_msg, print_info, print_error


class Ajaris:
    def __init__(self, input_file, output_file):
        self.input = input_file
        self.output = output_file

        self._set_ouput_fieldnames()
        self._register_dialect()

        self.media_types = {
            "photo_main": "1",
            "photo_alt": "2",
            "web_page": "3",
            "pdf": "4",
            "audio": "5",
            "video_file": "6",
            "video_youtube": "7",
            "video_dailymotion": "8",
            "video_vimeo": "9",
        }

    def _set_ouput_fieldnames(self):
        self.output_fieldnames = [
            "cd_ref",
            "title",
            "url",
            "author",
            "description",
            "date",
            "type",
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

    def run(self):
        # Open CSV files
        with open(self.input, "r", newline="", encoding="utf-8") as f_src:
            total_csv_lines_nbr = self._calculate_csv_entries_number(f_src)

            reader = csv.DictReader(f_src, dialect="tsv")
            with open(self.output, "w", newline="", encoding="utf-8") as f_dest:
                writer = csv.DictWriter(f_dest, dialect="tsv", fieldnames=self.output_fieldnames)
                writer.writeheader()

                try:
                    for row in reader:
                        new_row = {
                            "cd_ref": row["cd_nom"],
                            "title": row["species"],
                            "url": self._build_url(row),
                            "author": row["author"],
                            "description": self._build_description(row["description"], row['num_photo']),
                            "date": self._transform_date(row["date"]),
                            "type": self._build_type(row),
                            "source": "CBNA (ICONO)",
                            "licence": "CC BY-NC-SA",
                        }
                        writer.writerow(new_row)
                except csv.Error as e:
                    sys.exit(f"Error in file {self.input}, line {reader.line_num}: {e}")

    def _calculate_csv_entries_number(self, file_handle):
        print_msg("Computing CSV file total number of entries...")
        total_lines = sum(1 for line in file_handle) - 1
        file_handle.seek(0)
        if total_lines < 1:
            print_error("Number of total lines in CSV file can't be lower than 1.")
            exit(1)

        print_info(f"Number of entries in CSV files: {total_lines} ")
        return total_lines

    def _build_url(self, row):
        # Default URL : http://www.cbn-alpin-icono.fr/Phototheque/media/img/displaybox
        # md5 Nging : echo -n /cbna/433356233/21468.jpg | md5sum | awk '{print $1}'
        url_base = Config.get('base_url')
        url = f"{url_base}/{row['session_id']}/{row['doc_id']}.jpg"
        return url

    def _build_description(self, desc, num_photo):
        output = []
        cleaned_desc = self._clean_description(desc)
        if cleaned_desc:
            output.append(cleaned_desc)
        output.append(f"Id : {num_photo}")
        return " ; ".join(output)

    def _clean_description(self, desc):
        return (desc
            .replace('_Description : ', ' ; Description : ')
            .replace('_Commentaire : ', ' ; Commentaire : ')
            .replace('_Lieu : ', ' ; Lieu : ')
        )

    def _transform_date(self, date):
        formated_date = "\\N"
        if re.match(r"^[0-3][0-9]\/[0-1][0-9]\/[1-2][0-9]{3}$", date):
            splited_date = date.split("/")
            splited_date.reverse()
            year = splited_date[0]
            month = splited_date[1]
            day = splited_date[2]
            if self._is_valid_date(year=year, month=month, day=day):
                formated_date = "-".join(splited_date)
        return formated_date

    def _is_valid_date(self, year, month, day):
        is_valid_date = True
        try:
            datetime.datetime(int(year), int(month), int(day))
        except ValueError:
            is_valid_date = False
        return is_valid_date

    def _build_type(self, row):
        media_type = self.media_types["photo_alt"]
        if "type" in row:
            type = row["type"]
            if type in self.media_types:
                media_type = self.media_types[type]
            else:
                print_error(f"Media type '{type}' is not supported!")
        return media_type

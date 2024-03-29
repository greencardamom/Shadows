#!/usr/bin/env python3
# coding: utf-8
# SPDX-License-Identifier: Apache-2.0

# Source    : https://phabricator.wikimedia.org/P17710
# Background: https://phabricator.wikimedia.org/T267992

# Copyright 2021 AntiCompositeNumber
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Tag enwiki files that have the same name as a different Commons file"""

import pymysql
import logging
from collections import namedtuple

__version__ = "0.1.0"

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("shadows")

FileRecord = namedtuple("FileRecord", ["name", "sha1"])


def get_enwiki_files(prefix):
    """Queries the enwiki database for file titles and SHA-1 hashes"""
    exclude = [
        "ShadowsCommons",
        "Shadows_commons",
        "Now_Commons",
        # "Do_not_move_to_commons",
        "Ffd",
        "Deletable_file",
        "Db-nowcommons",
        "Pp-template",
        "Keep_local_high-risk",
        "Keep_local",
        "Pp-upload",
        "C-uploaded",
        "Protected_sister_project_logo",
        "Rename_media",
    ]
    query = """
    SELECT img_name, img_sha1
    FROM image
    JOIN page ON page_title = img_name AND page_namespace = 6
    LEFT JOIN templatelinks ON (
        tl_from = page_id
        AND tl_namespace = 10
        AND tl_title IN %(exclude)s
    )
    WHERE
        img_sha1 LIKE %(prefix)s
        AND tl_from IS NULL
    """
    with pymysql.connect(
        database="enwiki_p",
        host="enwiki.analytics.db.svc.wikimedia.cloud",
        read_default_file="~/replica.my.cnf",
        charset="utf8mb4",
    ) as cur:
        cur.execute(query, {"prefix": prefix, "exclude": exclude})
        data = cur.fetchall()

    return {
        FileRecord(str(name, encoding="utf-8"), str(sha1, encoding="utf-8"))
        for name, sha1 in data
    }


def get_commons_hashes(batch):
    """Takes a list of titles and retrieves the corresponding SHA-1 hashes"""
    query = """
    SELECT img_name, img_sha1
    FROM image
    JOIN page ON page_title = img_name AND page_namespace = 6
    LEFT JOIN templatelinks ON (
        tl_from = page_id
        AND tl_namespace = 10
        AND tl_title = 'Deletion_template_tag'
    )
    WHERE
        img_name IN %(titles)s
        AND tl_from IS NULL
    """
    with pymysql.connect(
        database="commonswiki_p",
        host="commonswiki.analytics.db.svc.wikimedia.cloud",
        read_default_file="~/replica.my.cnf",
        charset="utf8mb4",
    ) as cur:
        cur.execute(query, {"titles": [record.name for record in batch]})
        data = cur.fetchall()

    return {
        FileRecord(str(name, encoding="utf-8"), str(sha1, encoding="utf-8"))
        for name, sha1 in data
    }


def iter_matches():
    """Yields FileRecords of shadowed files"""
    for i in range(0x00, 0x100):
        prefix = "{i:02x}%".format(i=i)
        # logger.info("Checking prefix: {prefix}".format(prefix=prefix[:-1]))
        enwiki_batch = get_enwiki_files(prefix)
        title_matches = get_commons_hashes(enwiki_batch)
        yield from title_matches.difference(enwiki_batch)


def main():
    for record in iter_matches():
        print(record.name)
    # logger.info("Finished")


if __name__ == "__main__":
    main()


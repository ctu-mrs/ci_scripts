#!/bin/python3

import os
import xml.etree.ElementTree as ET
import re

def clean_xml(file_path):

    """ Reads an XML file, removes invalid comments, and returns a clean string. """
    with open(file_path, "r", encoding="utf-8") as f:
        xml_content = f.read()

    # Remove illegal comments (e.g., those containing "--" incorrectly)
    xml_content = re.sub(r'<!\s*--[^>]*--\s*>', '', xml_content, flags=re.DOTALL)

    return xml_content.strip()  # Ensure root remains on the first line

def find_packages(root_dir):

    dependencies = set()

    package_path = os.path.join(root_dir, "package.xml")

    xml_content = clean_xml(package_path)

    root = ET.fromstring(xml_content)

    dependencies = [dep.text.strip() for dep in root.findall("depend") if dep.text]
    dependencies = dependencies + [dep.text.strip() for dep in root.findall("build_depend") if dep.text]

    return dependencies

def main(root_dir):

    deps = find_packages(root_dir)

    for dependency in deps:
        print(dependency)

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("Usage: python build_order.py <root_directory>")
    else:
        main(sys.argv[1])

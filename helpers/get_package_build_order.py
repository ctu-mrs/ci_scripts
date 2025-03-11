#!/bin/python3

import os
import xml.etree.ElementTree as ET
from collections import defaultdict, deque
import re
import graphlib

def clean_xml(file_path):

    """ Reads an XML file, removes invalid comments, and returns a clean string. """
    with open(file_path, "r", encoding="utf-8") as f:
        xml_content = f.read()
    
    # Remove illegal comments (e.g., those containing "--" incorrectly)
    xml_content = re.sub(r'<!\s*--[^>]*--\s*>', '', xml_content, flags=re.DOTALL)
    
    return xml_content.strip()  # Ensure root remains on the first line

def find_packages(root_dir):

    deb_ignore_file_path = os.path.join(root_dir, ".deb_ignore")

    ignore_packages = []

    if os.path.exists(deb_ignore_file_path):

        with open(deb_ignore_file_path, 'r') as f:

            ignore_packages = [line.strip("\n") for line in f]

    packages_set = set()
    packages_dependencies = {}
    packages_paths = {}
    pruned_depenencies = {}

    for subdir, _, files in os.walk(root_dir):

        dependencies = set()

        if "package.xml" in files:

            if os.path.exists(os.path.join(subdir, "CATKIN_IGNORE")):
                continue

            package_path = os.path.join(subdir, "package.xml")

            xml_content = clean_xml(package_path)           

            root = ET.fromstring(xml_content)

            name_elem = root.find("name")

            package_name = name_elem.text.strip()

            packages_paths[package_name] = os.path.relpath(subdir, root_dir)

            if package_name in ignore_packages:
                continue

            if name_elem is None:
                continue

            dependencies = [dep.text.strip() for dep in root.findall("depend") if dep.text]
            dependencies = dependencies + [dep.text.strip() for dep in root.findall("build_depend") if dep.text]
            dependencies = dependencies + [dep.text.strip() for dep in root.findall("exec_depend") if dep.text]
            dependencies = dependencies + [dep.text.strip() for dep in root.findall("run_depend") if dep.text]
            dependencies = dependencies + [dep.text.strip() for dep in root.findall("test_depend") if dep.text]

            
            packages_set.add(package_name)

            packages_dependencies[package_name] = dependencies

    for package in packages_set:

        dependencies = []

        for dependency in packages_dependencies[package]:

            if dependency in packages_set:

                dependencies.append(dependency)

        pruned_depenencies[package] = dependencies
    
    return pruned_depenencies, packages_paths

def main(root_dir):

    packages, packages_paths = find_packages(root_dir)

    ts = graphlib.TopologicalSorter(packages)

    ordered_list = [*tuple(ts.static_order())]

    for package in ordered_list:
        print("{} {}".format(package, packages_paths[package]))

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("Usage: python build_order.py <root_directory>")
    else:
        main(sys.argv[1])

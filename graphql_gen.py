#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os

print('Generating GraphQLConstants')

template = '''//
//  Generated code do not edit
//

enum GraphQLConstants {
'''

path = os.path.dirname(os.path.abspath(__file__))

os.chdir(path + '/Prime/Resources/graphql')

graphql_extension = '.graphql'
for root, dirs, files in os.walk('.'):
    for file in files:
        if file.endswith(graphql_extension):
            print('Found {}'.format(file))
            graphql_file = open(root + '/' + file)
            file_name = file.split('.')[0]
            template += '    static let {} = """\n{}\n"""\n'.format(
                file_name[0].lower() + file_name[1:], graphql_file.read()
            )
            graphql_file.close()

template += '}'

generated_file = open(path + '/Prime/Sources/Generated/GraphQLConstants.swift', 'w+')
generated_file.write(template)
generated_file.close()

print('Done')
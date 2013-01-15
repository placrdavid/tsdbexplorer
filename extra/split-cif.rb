#!/usr/bin/ruby
#
#  This file is part of TSDBExplorer.
#
#  TSDBExplorer is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
#
#  TSDBExplorer is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
#  Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with TSDBExplorer.  If not, see <http://www.gnu.org/licenses/>.
#
#  $Id$
#

=begin rdoc

Read a CIF file from STDIN and output only the scheduled operated by the specificed TOC(s).

The extracted data will contain all TIPLOCs for all locations, including those not referenced by the schedules.

=end

toc_code = ['LO']

raise "Please set toc_code in the script" if toc_code == Array.new

schedule = Array.new

while record = gets

  record_type = record[0..1]
  puts record if ['HD', 'TI', 'ZZ'].include? record_type
  next if ['AA', 'TI', 'TA', 'TD'].include? record_type

  schedule << record.chomp

  if record_type == "LT"

    if toc_code.include? schedule[1][11..12]
      puts schedule.join("\n")
    end

    schedule = Array.new

  end

end

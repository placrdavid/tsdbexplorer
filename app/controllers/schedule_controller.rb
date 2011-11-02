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

class ScheduleController < ApplicationController

  # Display a single schedule

  def index

    @schedule = nil
    @schedule = BasicSchedule.find_by_uuid(params[:uuid]) if params[:uuid]

    @as_run = DailySchedule.find_all_by_train_uid(@schedule.train_uid)

  end


  # Display a schedule by UID

  def schedule_by_uid

    @schedule = BasicSchedule.find_by_train_uid(params[:uid])

    if @schedule.nil?
      render 'common/error', :status => :not_found, :locals => { :message => "We couldn't find the schedule #{params[:uid]}." }
    else
      render
    end

  end


  # Display a schedule by UID and date

  def schedule_by_uid_and_run_date

    @schedule = BasicSchedule.runs_on_by_uid_and_date(params[:uid], params[:run_date]).first
    @as_run = DailySchedule.runs_on_by_uid_and_date(params[:uid], params[:run_date]).first

    if @schedule.nil?
      render 'common/error', :status => :not_found, :locals => { :message => "We couldn't find the schedule #{params[:uid]} running on #{params[:run_date]}.  The schedule may not be valid for this date." }
    else
      render
    end

  end


  # Display real-time information

  def actual

    @schedule = DailySchedule.find_by_uuid(params[:uuid])

    render 'common/_schedule_instance'

  end

end


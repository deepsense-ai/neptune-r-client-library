#
# Copyright (c) 2017, deepsense.io
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
import os
import sys
from git import Repo


def find_remote_parent_branch(repo, commit):
    branch_histories = {branch.name: list(repo.iter_commits(branch)) for branch in repo.branches}

    commit_history = list(repo.iter_commits(commit))
    for commit in commit_history:
        remote_branches_with_commit = []
        if repo.head.is_detached:
            sys.stderr.write('WARNING: HEAD is detached.\n')
            return None
        for branch in repo.branches:
            if commit in branch_histories[branch.name] and \
                (commit == commit_history[0] or branch.name != repo.active_branch.name) and \
                    branch.tracking_branch() is not None:
                remote_branches_with_commit.append(branch)

        if len(remote_branches_with_commit) > 1:
            sys.stderr.write('WARNING: The active branch has two remote parent branches.\n')
            return None
        elif remote_branches_with_commit:
            return remote_branches_with_commit[0].name

    sys.stderr.write('WARNING: No remote parent branch found.\n')
    return None


def get_branch_tag():
    repo = Repo('.')
    assert not repo.bare

    remote_parent_branch = find_remote_parent_branch(repo, repo.head)

    if remote_parent_branch:
        branch_latest_tag = remote_parent_branch.replace('/', '-') + '-latest'
    elif 'GERRIT_BRANCH' in os.environ:
        sys.stderr.write('Detected GERRIT_BRANCH environment variable.\n')
        branch_latest_tag = os.environ['GERRIT_BRANCH'].replace('/', '-') + '-latest'
    else:
        sys.stderr.write('No GERRIT_BRANCH environment variable, falling back to the latest docker.\n')
        branch_latest_tag = 'latest'

    sys.stderr.write('Calculated branch-specific tag for neptune-backend image: ' + branch_latest_tag + '\n')

    return branch_latest_tag


if __name__ == '__main__':
    print get_branch_tag()

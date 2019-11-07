1.  Write some release notes so they show up in the "What's new" section
2.  Make sure you are on master branch.
3.  Make sure all tests are passing:
    * bundle exec rake db:test:prepare
    * bundle exec rake test
4. git tag -a rel-<next_rel_number>
5. git push origin master
6. git push --tags origin master
7.  heroku maintenance:on -a cargoflux-
8.  heroku pg:backups capture -a cargoflux-
9.  heroku pg:backups -a cargoflux-
10.  git push heroku-
11.  heroku run bash -a cargoflux-
    * rake db:migrate:status
    * rake db:migrate
    * rake db:migrate:status
    * exit
12. heroku ps:scale booking=0 -a cargoflux-
13. heroku ps:scale booking=1 -a cargoflux-
14. heroku ps -a cargoflux-
15. heroku maintenance:off -a cargoflux-
16. heroku logs --tail -a cargoflux-

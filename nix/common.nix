{ lib }:
rec {
  options = rec {
    str = lib.mkOption {
      type = lib.types.nullishOrStringish;
      default = null;
    };

    path = str;

    name = str;

    id = str;

    uses = str;

    alias = str;

    with_ = lib.mkOption {
      type = lib.types.attrsOf lib.types.nullishOrStringish;
      default = { };
    };

    action = lib.types.submodule {
      options = {
        inherit name with_;
      };
    };

    actions = lib.mkOption {
      type = lib.types.attrsOf action;
      default = { };
    };

    step = {
      inherit
        id
        name
        uses
        with_
        alias
        ;
    };

    job = {
      inherit name;
    };

    on = lib.mkOption {
      type = lib.types.submodule {
        options =
          let
            strings = lib.mkOption {
              type = lib.types.nullOr (lib.types.listOf lib.types.str);
              default = null;
            };

            mkTypesOption =
              types:
              lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.listOf (if types != [ ] then lib.types.strOneOf types else lib.types.str)
                );
                default = [ ];
              };

            commonPushPR = types: {
              branches = strings;
              branches-ignore = strings;
              paths = strings;
              paths-ignore = strings;
              types = mkTypesOption types;
            };

            mkSubmoduleOption =
              options:
              lib.mkOption {
                type = lib.types.nullOr (lib.types.submodule { inherit options; });
                default = null;
              };

            # https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions

            push = mkSubmoduleOption (
              commonPushPR events_.push
              // {
                tags = strings;
                tags-ignore = strings;
              }
            );

            pull_request = mkSubmoduleOption (commonPushPR events_.pull_request);

            pull_request_target = mkSubmoduleOption (commonPushPR events_.pull_request_target);

            schedule = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.listOf (
                  lib.types.submodule {
                    options = {
                      cron = lib.mkOption { type = lib.types.str; };
                    };
                  }
                )
              );
              default = null;
            };

            # https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows
            events_ = {
              branch_protection_rule = [
                "created"
                "edited"
                "deleted"
              ];
              check_run = [
                "created"
                "rerequested"
                "completed"
                "requested_action"
              ];
              check_suite = [ "completed" ];
              create = null;
              delete = null;
              deployment = null;
              deployment_status = null;
              discussion = [
                "created"
                "edited"
                "deleted"
                "transferred"
                "pinned"
                "unpinned"
                "labeled"
                "unlabeled"
                "locked"
                "unlocked"
                "category_changed"
                "answered"
                "unanswered"
              ];
              discussion_comment = [
                "created"
                "edited"
                "deleted"
              ];
              fork = null;
              gollum = null;
              issue_comment = [
                "created"
                "edited"
                "deleted"
              ];
              issues = [
                "opened"
                "edited"
                "deleted"
                "transferred"
                "pinned"
                "unpinned"
                "closed"
                "reopened"
                "assigned"
                "unassigned"
                "labeled"
                "unlabeled"
                "locked"
                "unlocked"
                "milestoned"
                "demilestoned"
              ];
              label = [
                "created"
                "edited"
                "deleted"
              ];
              merge_group = [ "checks_requested" ];
              milestone = [
                "created"
                "closed"
                "opened"
                "edited"
                "deleted"
              ];
              page_build = null;
              project = [
                "created"
                "closed"
                "reopened"
                "edited"
                "deleted"
              ];
              project_card = [
                "created"
                "moved"
                "converted to an issue"
                "edited"
                "deleted"
              ];
              project_column = [
                "created"
                "updated"
                "moved"
                "deleted"
              ];
              public = null;
              pull_request = [
                "assigned"
                "unassigned"
                "labeled"
                "unlabeled"
                "opened"
                "edited"
                "closed"
                "reopened"
                "synchronize"
                "converted_to_draft"
                "locked"
                "unlocked"
                "enqueued"
                "dequeued"
                "milestoned"
                "demilestoned"
                "ready_for_review"
                "review_requested"
                "review_request_removed"
                "auto_merge_enabled"
                "auto_merge_disabled"
              ];
              # pull_request_comment - not applicable
              pull_request_review = [
                "submitted"
                "edited"
                "dismissed"
              ];
              pull_request_review_comment = [
                "created"
                "edited"
                "deleted"
              ];
              pull_request_target = [
                "assigned"
                "unassigned"
                "labeled"
                "unlabeled"
                "opened"
                "edited"
                "closed"
                "reopened"
                "synchronize"
                "converted_to_draft"
                "ready_for_review"
                "locked"
                "unlocked"
                "review_requested"
                "review_request_removed"
                "auto_merge_enabled"
                "auto_merge_disabled"
              ];
              push = null;
              registry_package = [
                "published"
                "updated"
              ];
              release = [
                "published"
                "unpublished"
                "created"
                "edited"
                "deleted"
                "prereleased"
                "released"
              ];
              repository_dispatch = [ ];
              # schedule - not applicable;
              status = null;
              watch = [ "started" ];
              workflow_call = null;
              workflow_dispatch = null;
              workflow_run = [
                "completed"
                "requested"
                "in_progress"
              ];
            };

            mkEventOption =
              types: mkSubmoduleOption (lib.optionalAttrs (types != null) { types = mkTypesOption types; });

            events = lib.mapAttrs (_: mkEventOption) events_;

            workflow_call = mkSubmoduleOption {
              inputs = lib.mkOption {
                type = lib.types.attrsOf (
                  lib.types.submodule {
                    options = {
                      description = lib.mkOption {
                        type = lib.types.nullishOrStringish;
                        default = null;
                      };
                      type = lib.mkOption {
                        type = lib.types.strOneOf [
                          "boolean"
                          "number"
                          "string"
                        ];
                      };
                      default = lib.mkOption {
                        # TODO make dependent on type?
                        # requires inspection of configuration
                        type = lib.types.nullOr (
                          lib.types.oneOf [
                            lib.types.bool
                            lib.types.number
                            lib.types.str
                          ]
                        );
                        default = null;
                      };
                      required = lib.mkOption {
                        type = lib.types.nullOr lib.types.bool;
                        default = null;
                      };
                    };
                  }
                );
              };

              outputs = lib.mkOption {
                type = lib.types.attrsOf (
                  lib.types.submodule rec {
                    options = {
                      description = str;
                      value = str;
                    };
                  }
                );
              };

              secrets = lib.mkOption {
                type = lib.types.attrsOf (
                  lib.types.submodule {
                    options = {
                      description = str;
                      required = lib.mkOption {
                        type = lib.types.nullOr lib.types.bool;
                        default = null;
                      };
                    };
                  }
                );
              };
            };

            workflow_run = mkSubmoduleOption rec {
              branches = strings;
              branches-ignore = strings;
            };

            workflow_dispatch = mkSubmoduleOption {
              inputs = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.attrsOf (
                    lib.types.submodule {
                      options = {
                        description = str;
                        required = lib.mkOption {
                          type = lib.types.nullOr lib.types.bool;
                          default = null;
                        };
                        type = lib.mkOption {
                          type = lib.types.strOneOf [
                            "boolean"
                            "choice"
                            "number"
                            "environment"
                            "string"
                          ];
                        };
                        # TODO make dependent on type?
                        # requires inspection of configuration
                        default = lib.mkOption {
                          type = lib.types.oneOf [
                            lib.types.bool
                            lib.types.str
                            lib.types.number
                          ];
                        };
                        options = lib.mkOption { type = lib.types.nullOr (lib.types.listOf lib.types.str); };
                      };
                    }
                  )
                );
                default = null;
              };
            };
          in
          events
          // {
            inherit
              pull_request
              pull_request_target
              push
              schedule
              workflow_call
              workflow_run
              workflow_dispatch
              ;
          };
      };
    };
  };
}

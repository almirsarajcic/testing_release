defmodule GithubWorkflows do
  def get do
    %{
      "main.yml" => main_workflow()
    }
  end

  defp main_workflow do
    [
      [
        name: "Test Elixir release",
        on: "push",
        jobs: [
          test_release: [
            name: "Build and test release",
            "runs-on": "ubuntu-latest",
            env: [
              FLY_APP_NAME: "testing_release",
              FLY_PRIVATE_IP: "0:0:0:0:0:0:0:1",
              PHX_HOST: "localhost",
              SECRET_KEY_BASE: "8qdSYkvbFbYhUIKIPGsQOoOVdGUIzR+Sh56BJ0E+SU1xD4EsQMV5zCOSgRC5U8Rf"
            ],
            steps: [
              [
                name: "Checkout",
                uses: "actions/checkout@v3"
              ],
              [
                name: "Set up Docker Buildx",
                uses: "docker/setup-buildx-action@v1"
              ],
              [
                name: "Cache Docker layers",
                uses: "actions/cache@v3",
                with: [
                  path: "/tmp/.buildx-cache",
                  key: "${{ runner.os }}-buildx-${{ github.sha }}",
                  "restore-keys": "${{ runner.os }}-buildx"
                ]
              ],
              [
                name: "Build image",
                uses: "docker/build-push-action@v2",
                with: [
                  context: ".",
                  builder: "${{ steps.buildx.outputs.name }}",
                  tags: "testing_release:latest",
                  load: true,
                  "build-args": "target=testing_release",
                  "cache-from": "type=local,src=/tmp/.buildx-cache",
                  "cache-to": "type=local,dest=/tmp/.buildx-cache-new,mode=max"
                ]
              ],
              [
                # Temp fix
                # https://github.com/docker/build-push-action/issues/252
                # https://github.com/moby/buildkit/issues/1896
                name: "Move cache",
                run: "rm -rf /tmp/.buildx-cache\nmv /tmp/.buildx-cache-new /tmp/.buildx-cache"
              ],
              [
                name: "Create the container",
                id: "create_container",
                run:
                  "echo ::set-output name=container_id::$(docker create -p 4000:4000 -e FLY_APP_NAME=${{ env.FLY_APP_NAME }} -e FLY_PRIVATE_IP=${{ env.FLY_PRIVATE_IP }} -e PHX_HOST=${{ env.PHX_HOST }} -e SECRET_KEY_BASE=${{ env.SECRET_KEY_BASE }} testing_release | tail -1)"
              ],
              [
                name: "Start the container",
                run: "docker start ${{ steps.create_container.outputs.container_id }}"
              ],
              [
                name: "Check HTTP status code",
                uses: "nick-fields/retry@v2",
                with: [
                  command:
                    "INPUT_SITES='[\"http://localhost:4000/api\"]' INPUT_EXPECTED='[200]' ./scripts/check_status_code.sh",
                  max_attempts: 3,
                  retry_wait_seconds: 5,
                  timeout_seconds: 1
                ]
              ],
              [
                name: "Write Docker logs to a file",
                if: "failure() && steps.create_container.outcome == 'success'",
                run:
                  "docker logs ${{ steps.create_container.outputs.container_id }} >> docker.log"
              ],
              [
                name: "Upload Docker log file",
                if: "failure()",
                uses: "actions/upload-artifact@v3",
                with: [
                  name: "docker.log",
                  path: "docker.log"
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  end
end

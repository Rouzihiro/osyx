module.exports = async ({ github, context, core }) => {
  const owner = context.repo.owner;
  const repo = context.repo.repo;
  const target = ".gitmodules";
  let changed = false;

  if (context.eventName === "workflow_dispatch") {
    changed = true;
  } else if (context.payload.pull_request) {
    const prNumber = context.payload.pull_request.number;
    const files = await github.paginate(github.rest.pulls.listFiles, {
      owner,
      repo,
      pull_number: prNumber,
      per_page: 100,
    });
    changed = files.some((f) => f.filename === target);
  } else if (context.payload.before && context.payload.after) {
    const base = context.payload.before;
    const head = context.payload.after;

    if (/^0+$/.test(base)) {
      changed = true;
    } else {
      const cmp = await github.rest.repos.compareCommits({
        owner,
        repo,
        base,
        head,
      });
      changed = (cmp.data.files || []).some((f) => f.filename === target);
    }
  } else {
    changed = true;
  }

  core.setOutput("changed", changed ? "true" : "false");
};

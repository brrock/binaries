import { Hono } from 'hono';

const app = new Hono();

// Redirect `/` to the GitHub repository
app.get('/', (c) => {
  return c.redirect("https://github.com/brrock/binaries", 302);
});

// Middleware to handle redirection for arm64/amd64 folders
app.get('/:arch/:file', (c) => {
  const { arch } = c.req.param();
  const { file } = c.req.param();

  // Validate the architecture
  if (arch !== 'arm64' && arch !== 'amd64') {
    return c.text('Invalid architecture', 400);
  }

  // Construct the GitHub User Content URL
  const githubUrl = `https://raw.githubusercontent.com/brrock/binaries/main/${arch}/${file}`;

  // Redirect to the GitHub User Content URL
  return c.redirect(githubUrl, 302);
});

// Default route for unmatched paths
app.all('*', (c) => c.text('Not Found', 404));

export default app;

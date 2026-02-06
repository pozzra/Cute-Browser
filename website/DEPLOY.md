# How to Host on Vercel

Since your website is in a subfolder (`website/`) of your repository, you need to configure Vercel slightly differently.

## Option 1: Automatic Deployment (Recommended)

1.  Push your latest code to GitHub:
    ```bash
    git add .
    git commit -m "Add website"
    git push
    ```
2.  Go to [Vercel Dashboard](https://vercel.com/dashboard).
3.  Click **"Add New..."** -> **"Project"**.
4.  Import your **Cute-Browser** repository.
5.  **Important:** In the "Configure Project" screen, look for **"Root Directory"**.
    - Click **Edit**.
    - Select the `website` folder.
6.  Click **Deploy**.

## Option 2: Using Vercel CLI

1.  Install Vercel CLI:
    ```bash
    npm i -g vercel
    ```
2.  Navigate to the website folder:
    ```bash
    cd website
    ```
3.  Run deploy:
    ```bash
    vercel
    ```
4.  Follow the prompts (say 'yes' to defaults).

## Verify

Your site will be live at `https://cute-browser-landing.vercel.app` (or similar).

Clone the Repo Open your terminal, go to your dev folder, and run:
git clone https://github.com/SarveshMahalingam/unihack26.git cd unihack26

Set Up the Python Environment I exported a cross-platform Conda environment file so we all have the exact same versions of FastAPI and the Gemini SDK. Run this from the root folder:
conda env create -f environment.yml 
conda activate unihack26

Add the API Keys (CRITICAL) For security, the .env file and the database are ignored by Git. You need to create your own local .env file to use the Gemini features.
cd backend

Create a new file named .env

Add this exact line inside the file:

Plaintext GEM_API="[PASTE_THE_KEY_HERE]" (Send them the actual Gemini API key in a secure DM, don't put it in the main chat!)

Start the Server Make sure you are inside the backend/ folder and your unihack26 conda environment is activated, then run:
Bash uvicorn app.main:app --reload If you see Application startup complete in your terminal, the server is running at http://127.0.0.1:8000 and the local SQLite database is ready to go!

Running Flutter App

https://www.notion.so/Flutter-Installation-and-basic-commands-322be02c135b80309d41efc10687f7a8

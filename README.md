# My developer image for docker

```docker build -t johnae/dev .``` builds the image

You MUST place and encrypted id_rsa key in the repo (call it "id_rsa"). This key is used when building the image and is also put in the user account inside the image.
You MUST also place "authorized_keys" within this repository (ignored in .gitignore) for any keys you wish to have access to the user account within the image.
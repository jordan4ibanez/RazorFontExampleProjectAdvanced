import std.stdio;

import Font = razor_font.razor_font;

import Window  = window.window;
import Camera  = camera.camera;
import Shader  = shader.shader;
import Texture = texture.texture;
import Math    = doml.math;
import mesh.mesh;
import doml.vector_2d;
import delta_time;


//! IMPORTANT: If you did not read the intermediate tutorial, I highly recommend you go and do that!
//! Only NEW pieces will be explained!
//! https://github.com/jordan4ibanez/RazorFontExampleProjectIntermediate/blob/main/source/app.d


void main()
{
    Window.initialize();
    Window.setTitle("RazorFont Example Advanced");

    Shader.create("2d", "shaders/2d_vertex.vs", "shaders/2d_fragment.fs");
    Shader.createUniform("2d", "cameraMatrix");
    Shader.createUniform("2d", "objectMatrix");
    Shader.createUniform("2d", "textureSampler");

    Font.setRenderTargetAPICallString(
        (string input){
            Texture.addTexture(input);
        }
    );
    Font.setRenderFunc(
        (Font.RazorFontData fontData) {

            string fileLocation = Font.getCurrentFontTextureFileLocation();

            Mesh tempObject = new Mesh()
                .addVertices2d(fontData.vertexPositions)
                .addIndices(fontData.indices)
                .addTextureCoordinates(fontData.textureCoordinates)
                // Note here: We added a new layout storage element into our Mesh class!
                .addColors(fontData.colors) 
                .setTexture(Texture.getTexture(fileLocation))
                .finalize();

            tempObject.render("2d");
            tempObject.cleanUp();
        }
    );

    Font.createFont("example_fonts/totally_original", "mc", true);    
    Font.selectFont("mc");
    
    // I think you get the deal with setting up these vars by now :P
    double rads = 0.0;

    int letterIndex = 0;
    double letterOffsetY = 0.0;
    bool letterUp = true;
    
    double fancyRotation = 0.0;
    int fancyIndex = 0;

    int newLetterIndex = 0;
    double newLetterOffsetY = 0.0;
    bool newLetterUp = true;
    double newProgress = 0.0;
    
    while (!Window.shouldClose()) {

        calculateDelta();

        // We're going to get a circulare motion going here
        rads += getDelta() * 10.0;
        if (rads >= Math.PI) {
            rads -= Math.PI2; 
        }

        Window.pollEvents();
        Camera.clearDepthBuffer();
        
        Window.clear(0.9);
        
        Shader.startProgram("2d");
        Font.setCanvasSize(Window.getWidth, Window.getHeight);
        
        Shader.setUniformMatrix4("2d", "cameraMatrix", Camera.updateGuiMatrix());
        Shader.setUniformMatrix4("2d", "objectMatrix", Camera.setGuiObjectMatrix() );

        // Alright, let's begin

        Font.enableShadows();
        Font.switchColors(1,0,0);

        // This is simply creating a 2d point from an angle
        double offsetX = Math.cos(rads);
        double offsetY = Math.sin(rads);

        // Now we apply it to the shadow
        Font.setShadowOffset(offsetX, offsetY);

        // You can switch the shadow color on the fly
        Font.switchShadowColor(0,0,1);

        int fontSize = 50;
        string hello = "hi there";
        Font.renderToCanvas(100, 100, fontSize, hello);

        /**
        You must enable shadows before you get the size of the text with shadows
        IF you want to include it in your calculation.
        */

        // So this is it with the calculation
        Font.enableShadows();
        Font.switchColors(1,0,0);
        Font.setShadowOffset(offsetX, offsetY);
        string infoString = "With";
        auto textSize = Font.getTextSize(fontSize, infoString);
        double posY = Window.getHeight - textSize.height;
        Font.renderToCanvas(10, posY, fontSize, infoString);
        /**
        You see how the shadow is moving up and down and the text is moving
        left and right? This is because we are subtracting the circular motion
        from the individual components of the text and creating a sawing motion
        between two separate axis.

        The motion is still there, but it's constantly being fought by repositioning 
        the y position of the font.

        So let's do that again without including the shadow
        */
        
        string newInfoString = "without";
        Font.setShadowOffset(offsetX, offsetY);
        textSize = Font.getTextSize(fontSize, newInfoString);
        Font.enableShadows();
        posY = Window.getHeight - textSize.height;
        Font.renderToCanvas(200, posY, fontSize, newInfoString);

        /**
        See? That difference can be extremely useful!

        Did you notice that I set the shadow color to blue,
        yet it didn't affect "with" and "without"? This is because
        the shadow color will reset back to black when you renderToCanvas().

        Also, the shadow offset resets to the default value so you don't
        end up with a headache trying to figure out where your logic
        loop is leaking memory allocations back into the offset!


        Now let's get started showcasing a brand new feature:
        Text manipulation! :D
        */

        Font.switchColors(0,0,1);
        string moveText = "Woooo!";
        const auto moveTextFontSize = Font.getTextSize(80, moveText);
        // Enabling shadows for example
        Font.enableShadows();
        // Center it
        double posX = (Window.getWidth / 2.0) - (moveTextFontSize.width / 2.0);
        posY = (Window.getHeight / 2.0) - (moveTextFontSize.height / 2.0);
        Font.renderToCanvas(posX, posY, 80, moveText);

        int realTextLength = Font.getTextRenderableCharsLength(moveText);

        // You'll know why it's (realTextLength * 2) soon
        int cursorPos = Font.getCurrentCharacterIndex() - (realTextLength * 2);

        // Doing this a bit more verbosely for the tutorial

        const double multiplier = 100;
        // Move up
        if (letterUp) {
            letterOffsetY += getDelta() * multiplier;

            if (letterOffsetY >= 20) {
                letterOffsetY = 20;
                letterUp = false;
            }
        }
        // Move down
        else {
            letterOffsetY -= getDelta() * multiplier;
            
            if (letterOffsetY <= 0) {
                letterOffsetY = 0;
                letterUp = true;
                // Move to next letter or wrap back around
                letterIndex++;
                if (letterIndex >= realTextLength) {
                    letterIndex = 0;
                }
            }
        }
        
        // Now move the base char
        Font.moveChar(cursorPos + letterIndex, 0, letterOffsetY);

        /**
        The shadow is striped in memory EXACTLY N (number of renderable characters)
        after the foreground!

        So all we have to do is  move it forwards that many times to also move the shadow
        */
        Font.moveChar(cursorPos + letterIndex + realTextLength, 0, letterOffsetY);

        /**
        Tada!
        
        So now lets do some rotation!
        
        There's one thing about rotation I want you to remember:

        Since all we have to work with internally are raw vertex positions,
        you must moveChar() and then rotateChar() so that the vertex centers
        are calculatable properly. 

        */

        // Why yes, this is a Vinesauce reference
        string speen = "Speeeeen";

        Font.enableShadows();
        Font.switchColors(0.4,0.25,1);
        Font.switchShadowColor(1,0,0);

        Font.renderToCanvas(posX, posY + 100, 55, speen);

        realTextLength = Font.getTextRenderableCharsLength(speen);
        cursorPos = Font.getCurrentCharacterIndex() - (realTextLength * 2);


        fancyRotation += getDelta() * 10;

        // So math.pi2 is pi * 2 which is 6.28 aka 360 degrees
        if (fancyRotation >= Math.PI2) {
            fancyRotation = 0;
            fancyIndex++;
            if (fancyIndex >= realTextLength) {
                fancyIndex = 0;
            }
        }
        
        // We have to do the same thing for the shadows, that we did above
        Font.rotateChar(cursorPos + fancyIndex, fancyRotation);
        Font.rotateChar(cursorPos + fancyIndex + realTextLength, fancyRotation);

        /**
        Let's combine them!

        We're going to reuse some variables from before because I don't feel like
        making a bunch more for this part :P
        */

        string combined = "Now combine 'em!";
        Font.switchColors(0,0,1);
        Font.enableShadows();
        Font.renderToCanvas(posX, posY + 200, 55, combined);

        int newRealTextLength = Font.getTextRenderableCharsLength(combined);
        int newCursorPos = Font.getCurrentCharacterIndex() - (newRealTextLength * 2);

        const double newMultiplier = 100;
        // Move up
        if (newLetterUp) {
            newLetterOffsetY += getDelta() * newMultiplier;
            newProgress += getDelta() * multiplier;

            if (newLetterOffsetY >= 20) {
                newLetterOffsetY = 20;
                newLetterUp = false;
            }
        }
        // Move down
        else {
            newLetterOffsetY -= getDelta() * newMultiplier;
            newProgress += getDelta() * multiplier;
            
            if (newLetterOffsetY <= 0) {
                newLetterOffsetY = 0;
                newLetterUp = true;
                // Move to next letter or wrap back around
                newLetterIndex++;
                newProgress = 0;
                if (newLetterIndex >= newRealTextLength) {
                    newLetterIndex = 0;
                }
            }
        }
        
        Font.moveChar(newCursorPos + newLetterIndex, 0, newLetterOffsetY * 2.0);
        Font.moveChar(newCursorPos + newLetterIndex + newRealTextLength, 0, newLetterOffsetY * 2.0);

        double newRotation = (newProgress / 40.0) * Math.PI2;

        Font.rotateChar(newCursorPos + newLetterIndex,  newRotation);
        Font.rotateChar(newCursorPos + newLetterIndex + newRealTextLength, newRotation);

        /**
        So that's about it, hopefully this library helps you with your game endeavors!
        */        
            
        Font.render();
        
        Window.swapBuffers();
    }
    
    Shader.deleteShader("2d");
    Texture.cleanUp();
    Window.destroy();

}

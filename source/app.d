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
    int letterUp = true;
    
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
        const auto moveTextFontSize = Font.getTextSize(50, moveText);
        // Enabling shadows for example
        Font.enableShadows();
        // Center it
        double posX = (Window.getWidth / 2.0) - (moveTextFontSize.width / 2.0);
        posY = (Window.getHeight / 2.0) - (moveTextFontSize.height / 2.0);
        Font.renderToCanvas(posX, posY, fontSize, moveText);

        const int realTextLength = Font.getTextRenderableCharsLength(moveText);

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
        




        

        
            
        Font.render();
        
        Window.swapBuffers();
    }
    
    Shader.deleteShader("2d");
    Texture.cleanUp();
    Window.destroy();

}

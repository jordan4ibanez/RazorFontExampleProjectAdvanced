import std.stdio;

import Font = razor_font;

import Window  = window.window;
import Camera  = camera.camera;
import Shader  = shader.shader;
import Texture = texture.texture;
import Math    = doml.math;
import mesh.mesh;
import doml.vector_2d;


//! IMPORTANT: If you did not read the simple tutorial, I highly recommend you go and do that!
//! Only NEW pieces will be explained!
//! https://github.com/jordan4ibanez/RazorFontExampleProject

/**
Also another note:
There have been changes to shaders/2d_fragment.fs to allow RazorFont to use
these more advanced features. I suggest you give it a glance. :D
*/

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

    // We're only going to use the mc font this time
    Font.selectFont("mc");

    // You'll find out what this is for later!
    double theBeach = 0.0;
    double rainbowsX = 0.0;
    double rainbowsY = 0.0;
    
    while (!Window.shouldClose()) {

        Window.pollEvents();
        Camera.clearDepthBuffer();
        
        Window.clear(0.9);
        
        Shader.startProgram("2d");
        Font.setCanvasSize(Window.getWidth, Window.getHeight);
        
        Shader.setUniformMatrix4("2d", "cameraMatrix", Camera.updateGuiMatrix());
        Shader.setUniformMatrix4("2d", "objectMatrix", Camera.setGuiObjectMatrix() );


        {
            // So you can set the letter colors before....
            Font.setColorChar(0, 1,0,0,0.5);
            Font.setColorChar(1, 0,1,0);
            Font.setColorChar(2, 0,0,1);
            
            int fontSize = 50;
            string textString = "Hello, I'm your test text :)";

            Font.RazorTextSize textSize = Font.getTextSize(fontSize, textString);

            // Now we're going to move slightly above the center point of the window
            double posX = (Window.getWidth / 2.0) - (textSize.width / 2.0);
            double posY = (Window.getHeight / 2.0) - (textSize.height / 2.0);

            Font.renderToCanvas(posX, posY, fontSize, textString);

            /**
            ...And after rendering to canvas. The color cache is always there.
            I recommend doing it after so you can work backwards from the next position/
            This is explained more later on!
            */
            Font.setColorChar(3, 0.5,0.5,0.5);

            /**
            Let's do something REALLY fancy!
            
            Let's set the second l and o to a blue to white blend
            */

            Font.setColorPoints(4,/*Left points*/[0.,0,1,1],[0.,0,1,1], /*Right points*/[1.,1,1,1],[1.,1,1,1]);
            Font.setColorPoints(5,/*Left points*/[0.,0,1,1],[0.,0,1,1], /*Right points*/[1.,1,1,1],[1.,1,1,1]);

            /**
            Now let's get even crazier! Let's do primary colors on the first 3,
            and yellow on the last one, I'm going to use the super verbose version of setColorPoints.
            It's overloaded :D

            This is going into the letter I in (I'm)
            */
            Font.setColorPoints(
                6,
                1,0,0,1,
                0,1,0,1,
                0,0,1,1,
                1,1,0,1,
            );

            /**
            Looks kinda like a mat4 opengl and vulkan matrix. :P


            So this one just uses pcgRandom to make some crazy colors. Pretty standard. :D

            You can see that the range func does an inclusive start, exclusive end
            just like you're used to in D by the following code:
            */

            // This is targeting ('m) in (I'm)
            Font.setColorRange(7,9, Math.random(),Math.random(),Math.random(),1);

            /**

            So now, straight to the insane asylum. Let's animate this text with colors!

            It's almost spring at the time of writing this, and I want to go fishing.

            So let's make this look like the waves of the ocean.
            */
            {
                import delta_time;

                calculateDelta();

                theBeach += getDelta();
                
                if (theBeach > Math.PI) {
                    theBeach -= Math.PI2;
                }

                /*
                So you know how we rendered to the canvas before hand?

                Well, now we have the amount of characters currently on
                the canvas, so we can work backwards from that with ease!

                You could also use this to set up the next word in a multi-render
                to canvas to do some even crazier stuff :)

                Keep in mind, your typewriter arm is already above what would be the next character
                in the row without a carriage return.
                -1 shifts it onto the last currently rendered character.

                There's a reason that this isn't a const here, but I recommend you do that to avoid confusion.
                */
                int currentIndex = Font.getCurrentCharacterIndex() - 10;

                for (int i = currentIndex; i < currentIndex + 10; i++) {

                    // We want this to be a smooth flowing animation loop
                    // So we're gonna use some fancy math
                    const double left = theBeach + cast(double)i;
                    //! This is what I'm talking about below.
                    const double right = left + 1.0; 
                    
                    const double foam = 0.5;
                    double waterFlowLeft  = (Math.sin(left)  / 2.0) + foam;
                    double waterFlowRight = (Math.sin(right) / 2.0) + foam;

                    /**
                    So what we're doing here is basically creating a fixed,
                    smooth loop of data that's equal to an oscillating wave
                    form on a 2d plotter. We're starting from the left point
                    of that (data + index) to get somewhere on that data stream.
                    That's the left side done, so the easiest way to make this 
                    look ultra smooth is to just poll to the right to make
                    the compression of the 1d data stream get automatically mapped by opengl
                    into emulating the foam of a wave at the beach.

                    I left a little comment up above where the right half is, try changing
                    that to 2.5 or 3.5 and see what happens. :)

                    Now don't read the next part until you've tried that.

                    What you just did, was you created an overlap of the polling
                    into the data stream of the next character, looks pretty neat huh?

                    Makes things act a bit random and I suppose you could say "The sea gets rougher"
                    */
                    Font.setColorPoints(i,
                        waterFlowLeft,waterFlowLeft,1,1, // left
                        waterFlowLeft,waterFlowLeft,1,1,
                        waterFlowRight,waterFlowRight,1,1, //right
                        waterFlowRight,waterFlowRight,1,1
                    );
                }

                /**
                Did you notice that "your" is still solid black?
                The default buffer color is 0,0,0,1 rgba!

                Now remember, colors are in the color cache. If you want to reset the entire cache.
                Render, it moves the cursor back to 0, then run:
                Font.switchColors(r,g,b,a);

                You don't have to do this at all, but I thought someone could use it for something.
                So I added it in!



                So now I'm going to show you some magical rainbows.

                Change this to true, I wanted you to focus on what was
                happening on the center text before.
                */

                if (false) {

                    // We're going to use a special library I have for this :)
                    import fast_noise;
                    FNLState noise = fnlCreateState(1337);
                    noise.noise_type = FNLNoiseType.FNL_NOISE_OPENSIMPLEX2S;
                    noise.frequency = 1.0;

                    /**
                    So the noise can go -1, 1 so we're gonna fix that!
                    Now it can only go from 0.0 to 1.0 to match our RGB :D
                    */
                    double fixNoise(double input) {
                        input /= 2.0;
                        return Math.clamp(0.0, 1.0, input + 0.5);
                    }


                    // A reminder that if you store this as a string, there are tons of D helper functions!
                    string myCoolString = "I'm a magical rainbow flying through the sky!";

                    // Let's render at the top left this time
                    Font.renderToCanvas(0,0, 62, myCoolString);

                    /*
                    Oh look, we're using those two vars from earlier.

                    Let's send them on a long journey through the data void.
                    */
                    rainbowsX += getDelta();
                    rainbowsY += getDelta();
                    

                    // Easily 0 yourself back out to where you want. So here is: I in (I'm)
                    currentIndex = Font.getCurrentCharacterIndex() - Font.getTextRenderableCharsLength(myCoolString);

                    // We're going to run this like it's a game, and your text is literally walking through a 2d noise map
                    for(int i = currentIndex; i < currentIndex + myCoolString.length; i++) {

                        // I put this here because I don't want to type cast(double) a bunch of times
                        double rootX = cast(double)i;

                        /**
                        Okay, time to get those dang ol positions
                        */
                        double topLeftX = rootX + rainbowsX;
                        double topLeftY = rainbowsY;

                        double bottomLeftX = rootX + rainbowsX;
                        double bottomLeftY = 1 + rainbowsY;

                        double bottomRightX = 1 + rootX + rainbowsX;
                        double bottomRightY = 1 + rainbowsY;

                        double topRightX = 1 + rootX + rainbowsX;
                        double topRightY = rainbowsY;

                        /**
                        Now we have a 2d quad in pure positions! Neat!

                        So let's get that noise.

                        What we're doing here is we're polling RGB 100.0 units away from eachother
                        in the 2d noise map.

                        I wrote it out VERY verbosely so you can see exactly what this is doing!
                        */

                        // Uncomment this to see the data stream
                        // if (i == 23) {
                        //     writeln(fixNoise(fnlGetNoise2D(&noise, topLeftX, topLeftY)));
                        // }
                        
                        double[4] topLeftRGB = [
                            fixNoise(fnlGetNoise2D(&noise, topLeftX,         topLeftY)),
                            fixNoise(fnlGetNoise2D(&noise, topLeftX + 100.0, topLeftY)),
                            fixNoise(fnlGetNoise2D(&noise, topLeftX + 200.0, topLeftY)),
                            1 // Alpha
                        ];

                        double[4] bottomLeftRGB = [
                            fixNoise(fnlGetNoise2D(&noise, bottomLeftX,         bottomLeftY)),
                            fixNoise(fnlGetNoise2D(&noise, bottomLeftX + 100.0, bottomLeftY)),
                            fixNoise(fnlGetNoise2D(&noise, bottomLeftX + 200.0, bottomLeftY)),
                            1 // Alpha
                        ];

                        double[4] bottomRightRGB = [
                            fixNoise(fnlGetNoise2D(&noise, bottomRightX,         bottomRightY)),
                            fixNoise(fnlGetNoise2D(&noise, bottomRightX + 100.0, bottomRightY)),
                            fixNoise(fnlGetNoise2D(&noise, bottomRightX + 200.0, bottomRightY)),
                            1 // Alpha
                        ];

                        double[4] topRightRGB = [
                            fixNoise(fnlGetNoise2D(&noise, topRightX,         topRightY)),
                            fixNoise(fnlGetNoise2D(&noise, topRightX + 100.0, topRightY)),
                            fixNoise(fnlGetNoise2D(&noise, topRightX + 200.0, topRightY)),
                            1 // Alpha
                        ];
                        
                        // Now let's apply that to our text
                        Font.setColorPoints(i, topLeftRGB, bottomLeftRGB, bottomRightRGB, topRightRGB);

                        /**
                        Tada! Rainbow text wooo
                        */

                    }
                }
            }
        }

        /**
        One last thing I have to let you know. Did you notice that we
        never set the font during the loop of the program?

        If your program has only one font, you only need to set it at the
        entry point and never look at it again!

        Have fun. :D
        */
        
        // This is our only OpenGL render call in this entire program!
        Font.render();

        // Update the gl window yada yada
        Window.swapBuffers();
    }

    // Just regular ol opengl cleanup
    Shader.deleteShader("2d");
    Texture.cleanUp();
    Window.destroy();

}

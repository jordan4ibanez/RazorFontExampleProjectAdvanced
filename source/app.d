import std.stdio;

import Font = razor_font;

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
    
    double offset = 0.00;
    double offsetUp = true;
    
    while (!Window.shouldClose()) {

        calculateDelta();

        if (offsetUp) {
            offset += getDelta();
            if (offset >= 3) {
                offset = 3;
                offsetUp = false;                
            }
        } else {
            offset -= getDelta();
            if (offset <= 0) {
                offset = 0;
                offsetUp = true;
            }
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

        Font.setShadowOffset(offset,offset);
        Font.switchShadowColor(0,0,1);
        // Font.disableShadowColoring();

        int fontSize = 50;
        string hello = "hi there";

        auto textSize = Font.getTextSize(fontSize, hello);

        Font.renderToCanvas(0, 0, fontSize, hello);


        Font.switchColors(0,0,0);
        string infoString = "Sizing auto calculates shadows";

        textSize = Font.getTextSize(fontSize, infoString);

        double posY = Window.getHeight - textSize.height;

        Font.renderToCanvas(0, posY, fontSize, infoString);
        

        
            
        Font.render();
        
        Window.swapBuffers();
    }
    
    Shader.deleteShader("2d");
    Texture.cleanUp();
    Window.destroy();

}

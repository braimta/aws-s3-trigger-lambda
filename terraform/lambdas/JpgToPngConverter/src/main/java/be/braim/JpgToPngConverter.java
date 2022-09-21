package be.braim;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.S3Event;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;
import com.amazonaws.services.s3.model.S3Object;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;


/**
 * This lambda function converts a JPG image uploaded in an S3 bucket to a PNG. The purpose is only
 * to illustrate how a Lambda function can be triggered from an S3 event.
 *
 * Also, be aware that this code has been kept as simple as possible on purpose.
 *
 * @author Braim T (braimt@gmail.com)
 */
public class JpgToPngConverter implements RequestHandler<S3Event, String> {

    private AmazonS3 amazonS3Client = null;

    // Logs will be stored in CloudWatch logs.
    private LambdaLogger logger = null;

    /*
     * Entry point.
     */
    @Override
    public String handleRequest(S3Event input, Context context) {
        // initialize logger.
        logger = context.getLogger();

        // then process the event.
        processRequestedUpload(input);

        return null;
    }

    /**
     * Process the event. The payload contains many informations allowing us to process it; the file name
     * the bucket name, etc.
     */
    private void processRequestedUpload(S3Event s3Event) {
        amazonS3Client = AmazonS3ClientBuilder.defaultClient();

        // log the event in cloudwatch. it could be helpful for investigations if anything goes wrong.
        logger.log(String.format("Processing event %s", s3Event));

        //
        for (S3EventNotification.S3EventNotificationRecord record : s3Event.getRecords()) {
            // from the event, retrieve the name of the uploaded objects, derived output name and get the bucket name.
            String jpgFilename = record.getS3().getObject().getUrlDecodedKey();
            String pngFilename = jpgFilename.substring(jpgFilename.lastIndexOf("/") + 1).replaceAll("\\.jpg", ".png");
            String s3BucketName = record.getS3().getBucket().getName();

            try {
                // Get the S3 object.
                S3Object imageContent = amazonS3Client.getObject(s3BucketName, jpgFilename);
                BufferedImage bufferedImage = ImageIO.read(imageContent.getObjectContent());

                // Be careful!! In a lambda function, the only place where we are allowed to save a file is
                // in /tmp (https://aws.amazon.com/blogs/compute/choosing-between-aws-lambda-data-storage-options-in-web-apps/)
                File convertedImage = new File("/tmp/" + pngFilename);
                ImageIO.write(bufferedImage, "png", convertedImage);

                // then use the client to put it on the bucket.
                amazonS3Client.putObject(s3BucketName, "images/" + pngFilename, convertedImage);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }
    }
}

import coremltools as ct
import tensorflow as tf

# تحميل نموذج TensorFlow
model = tf.keras.models.load_model('First.h5')

# تحويل النموذج إلى صيغة Core ML
coreml_model = ct.convert(model,
    inputs=[ct.TensorType(shape=(1,), name='angle')],
    outputs=[
        ct.TensorType(name='rightProbability'),
        ct.TensorType(name='leftProbability')
    ]
)

# حفظ النموذج
coreml_model.save('First.mlmodel') 
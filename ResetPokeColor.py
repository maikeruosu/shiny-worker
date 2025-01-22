import logging
from JoycontrolPlugin import JoycontrolPlugin

logger = logging.getLogger(__name__)

class ResetPokeColor(JoycontrolPlugin):
    async def run(self):
        logger.info('This is ResetPokeColor')

        logger.info(f'Plugin Options: {self.options}')
        logger.info('Push the Home Button')
        await self.button_push('home')
        await self.wait(1)

        logger.info('Push the X Button')
        await self.button_push('x')
        await self.wait(1)

        logger.info('Push the A Button')
        await self.button_push('a')
        await self.wait(2.5)


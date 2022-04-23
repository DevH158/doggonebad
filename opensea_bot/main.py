from selenium import webdriver
from selenium.webdriver.chrome.service import Service as SC
from selenium.webdriver.firefox.service import Service as SG
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait as WDW
from selenium.common.exceptions import TimeoutException as TE
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By

from webdriver_manager.chrome import ChromeDriverManager as CDM

from os.path import abspath
from os import name as osname


class WebDriver:

    def __init__(self, browser_path: str):
        self.browser_path = browser_path
        self.driver = self.chrome()

    def chrome(self) -> webdriver:
        """Start a Chrome webdriver and return its state."""
        options = webdriver.ChromeOptions()  # Configure options for Chrome.
        # Add wallet extension according to user choice
        options.add_extension('Kaikas.crx')
        options.add_argument('log-level=3')  # No logs is printed.
        options.add_argument('--mute-audio')  # Audio is muted.
        options.add_argument('--disable-infobars')
        options.add_argument('--disable-popup-blocking')
        options.add_argument('--lang=en-US')  # Set webdriver language
        options.add_argument(' --disable-dev-shm-usage')
        options.add_experimental_option(  # to English. - 2 methods.
            'prefs', {'intl.accept_languages': 'en,en_US'})
        options.add_experimental_option('excludeSwitches', [
            'enable-logging', 'enable-automation'])
        driver = webdriver.Chrome(service=SC(  # DeprecationWarning using
            self.browser_path), options=options)  # executable_path.
        driver.maximize_window()  # Maximize window to reach all elements.
        return driver

    def visible(self, element: str):
        return WDW(self.driver, 5).until(
            EC.visibility_of_element_located((By.XPATH, element)))

    def clickable(self, element: str) -> None:
        try:
            WDW(self.driver, 5).until(EC.element_to_be_clickable(
                (By.XPATH, element))).click()
        except Exception:  # Some buttons need to be visible to be clickable,
            self.driver.execute_script(  # so JavaScript can bypass this.
                'arguments[0].click();', self.visible(element))

    def window_handles(self, window_number: int) -> None:
        WDW(self.driver, 10).until(lambda _: len(
            self.driver.window_handles) > window_number)
        self.driver.switch_to.window(  # Switch to the asked tab.
            self.driver.window_handles[window_number])

    def go_to_opensea(self):
        login_url = 'https://testnets.opensea.io/login?referrer=%2Faccount'
        self.driver.get(login_url)
        self.clickable('//button[contains(@class, "show-more")]')
        self.clickable(f'//*[contains(text(), "Kaikas")]/../..')

    def handle(self):
        self.driver.refresh()
        self.window_handles(0)
        self.go_to_opensea()
        print('hello')


if __name__ == '__main__':
    try:
        webdriver_ = 'ChromeDriver'
        print(f'Downloading the {webdriver_}.', end=' ')
        browser_path = CDM(log_level=0).install()
    except Exception:
        browser_path = abspath(
            'assets/' + 'chromedriver.exe' if osname == 'nt'
            else 'chromedriver'
        )

    wd = WebDriver(browser_path)
    wd.handle()